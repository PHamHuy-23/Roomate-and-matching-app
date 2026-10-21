package com.roommate.hub.service;

import com.roommate.hub.entity.MatchRequest;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.MatchRequestRepository;
import com.roommate.hub.repository.UserRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest
class MatchRequestConcurrencyIntegrationTest {

    @Autowired
    private MatchRequestService matchRequestService;

    @Autowired
    private MatchRequestRepository matchRequestRepository;

    @Autowired
    private UserRepository userRepository;

    private User userA;
    private User userB;

    @BeforeEach
    void setUp() {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        userA = userRepository.save(User.builder()
                .email("user-a-" + suffix + "@concurrency.test")
                .passwordHash("hash")
                .fullName("User A")
                .gender("MALE")
                .role(User.Role.ROLE_USER)
                .phone("0901111111")
                .build());

        userB = userRepository.save(User.builder()
                .email("user-b-" + suffix + "@concurrency.test")
                .passwordHash("hash")
                .fullName("User B")
                .gender("FEMALE")
                .role(User.Role.ROLE_USER)
                .phone("0902222222")
                .build());
    }

    @AfterEach
    void tearDown() {
        List<MatchRequest> list = matchRequestRepository.findConnectionsBetweenUsers(userA.getId(), userB.getId());
        matchRequestRepository.deleteAll(list);
        userRepository.delete(userA);
        userRepository.delete(userB);
    }

    @Test
    @DisplayName("Mô phỏng concurrency: A→B và B→A gửi đồng thời không tạo 2 bản ghi và không bị race condition")
    void concurrentBidirectionalSendRequest_ShouldResultInSingleAcceptedRecord() throws Exception {
        int threads = 2;
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        CountDownLatch readyLatch = new CountDownLatch(threads);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch doneLatch = new CountDownLatch(threads);

        AtomicInteger successCount = new AtomicInteger(0);
        ConcurrentLinkedQueue<Throwable> exceptions = new ConcurrentLinkedQueue<>();

        // Luồng 1: A -> B
        executor.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                matchRequestService.sendRequest(userA.getId(), userB.getId());
                successCount.incrementAndGet();
            } catch (Throwable t) {
                exceptions.add(t);
            } finally {
                doneLatch.countDown();
            }
        });

        // Luồng 2: B -> A (đồng thời)
        executor.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                matchRequestService.sendRequest(userB.getId(), userA.getId());
                successCount.incrementAndGet();
            } catch (Throwable t) {
                exceptions.add(t);
            } finally {
                doneLatch.countDown();
            }
        });

        // Đợi cả 2 luồng sẵn sàng
        readyLatch.await(5, TimeUnit.SECONDS);
        // Kích hoạt đồng thời
        startLatch.countDown();

        // Đợi cả 2 luồng hoàn tất
        boolean completed = doneLatch.await(10, TimeUnit.SECONDS);
        executor.shutdown();

        assertThat(completed).isTrue();
        assertThat(exceptions).isEmpty();
        assertThat(successCount.get()).isEqualTo(2);

        // Kiểm tra trong database: chỉ duy nhất 1 bản ghi tồn tại giữa 2 người dùng
        List<MatchRequest> connections = matchRequestRepository.findConnectionsBetweenUsers(userA.getId(), userB.getId());
        assertThat(connections).hasSize(1);

        // Bản ghi duy nhất này giữa 2 người dùng không bị duplicate hay race condition
        MatchRequest finalMatch = connections.get(0);
        assertThat(finalMatch.getStatus()).isIn(MatchRequest.MatchStatus.PENDING, MatchRequest.MatchStatus.ACCEPTED);
    }

    @Test
    @DisplayName("Mô phỏng concurrency: Hai phản hồi đồng thời (ACCEPT và REJECT) cho cùng 1 request chỉ cho phép 1 lần xử lý thành công")
    void concurrentRespondRequest_ShouldProcessOnlyOnce() throws Exception {
        // Tạo một MatchRequest PENDING ban đầu từ userA đến userB
        MatchRequest pendingRequest = matchRequestRepository.save(MatchRequest.builder()
                .sender(userA)
                .receiver(userB)
                .matchScore(85.0)
                .status(MatchRequest.MatchStatus.PENDING)
                .build());

        int threads = 2;
        ExecutorService executor = Executors.newFixedThreadPool(threads);
        CountDownLatch readyLatch = new CountDownLatch(threads);
        CountDownLatch startLatch = new CountDownLatch(1);
        CountDownLatch doneLatch = new CountDownLatch(threads);

        AtomicInteger successCount = new AtomicInteger(0);
        AtomicInteger failureCount = new AtomicInteger(0);
        ConcurrentLinkedQueue<Throwable> exceptions = new ConcurrentLinkedQueue<>();

        // Luồng 1: Chấp nhận (isAccepted = true)
        executor.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                matchRequestService.respondRequest(pendingRequest.getId(), true, userB.getId());
                successCount.incrementAndGet();
            } catch (Throwable t) {
                failureCount.incrementAndGet();
                exceptions.add(t);
            } finally {
                doneLatch.countDown();
            }
        });

        // Luồng 2: Từ chối (isAccepted = false)
        executor.submit(() -> {
            readyLatch.countDown();
            try {
                startLatch.await();
                matchRequestService.respondRequest(pendingRequest.getId(), false, userB.getId());
                successCount.incrementAndGet();
            } catch (Throwable t) {
                failureCount.incrementAndGet();
                exceptions.add(t);
            } finally {
                doneLatch.countDown();
            }
        });

        readyLatch.await(5, TimeUnit.SECONDS);
        startLatch.countDown();

        boolean completed = doneLatch.await(10, TimeUnit.SECONDS);
        executor.shutdown();

        assertThat(completed).isTrue();
        // Đúng 1 luồng thành công và đúng 1 luồng thất bại
        assertThat(successCount.get()).isEqualTo(1);
        assertThat(failureCount.get()).isEqualTo(1);

        // Luồng thất bại phải báo lỗi do yêu cầu đã được xử lý (IllegalArgumentException, ResponseStatusException hoặc OptimisticLockingFailureException)
        Throwable failedException = exceptions.peek();
        assertThat(failedException).isNotNull();
        boolean isExpectedException = failedException instanceof org.springframework.web.server.ResponseStatusException
                || failedException.getCause() instanceof org.springframework.web.server.ResponseStatusException
                || failedException instanceof org.springframework.dao.OptimisticLockingFailureException
                || failedException instanceof IllegalArgumentException
                || failedException.getCause() instanceof IllegalArgumentException;
        assertThat(isExpectedException).isTrue();

        // Kiểm tra database: trạng thái đã kết thúc và không còn là PENDING
        MatchRequest updatedRequest = matchRequestRepository.findById(pendingRequest.getId()).orElseThrow();
        assertThat(updatedRequest.getStatus()).isIn(MatchRequest.MatchStatus.ACCEPTED, MatchRequest.MatchStatus.REJECTED);
    }
}
