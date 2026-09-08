package com.roommate.hub.service;

import com.roommate.hub.entity.RoomPost;
import com.roommate.hub.entity.User;
import com.roommate.hub.repository.RoomPostRepository;
import com.roommate.hub.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final RoomPostRepository roomPostRepository;
    private final UserRepository userRepository;

    // Lấy toàn bộ bài đăng kèm trạng thái để kiểm duyệt
    public List<RoomPost> getAllPostsForModeration() {
        return roomPostRepository.findAll();
    }

    // Duyệt hoặc từ chối bài đăng
    @Transactional
    public RoomPost moderatePost(Long postId, String status) {
        RoomPost post = roomPostRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Bài đăng không tồn tại!"));

        post.setStatus(RoomPost.PostStatus.valueOf(status.toUpperCase()));
        return roomPostRepository.save(post);
    }

    // Lấy danh sách toàn bộ người dùng
    public List<User> getAllUsers() {
        return userRepository.findAll();
    }

    // Khóa hoặc mở khóa người dùng
    @Transactional
    public Map<String, Object> toggleUserStatus(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));

        // Nếu trạng thái đang là ACTIVE thì đổi thành LOCKED và ngược lại
        String newStatus = "ACTIVE".equalsIgnoreCase(user.getStatus()) ? "LOCKED" : "ACTIVE";
        user.setStatus(newStatus);
        userRepository.save(user);

        Map<String, Object> res = new HashMap<>();
        res.put("userId", user.getId());
        res.put("status", newStatus);
        return res;
    }
}