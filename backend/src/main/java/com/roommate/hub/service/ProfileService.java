package com.roommate.hub.service;

import com.roommate.hub.dto.UserPreferenceDTO;
import com.roommate.hub.dto.UserResponseDTO;
import com.roommate.hub.dto.PublicProfileResponseDTO;
import com.roommate.hub.entity.User;
import com.roommate.hub.entity.UserPreference;
import com.roommate.hub.exception.ForbiddenException;
import com.roommate.hub.exception.ResourceNotFoundException;
import com.roommate.hub.repository.BlockedUserRepository;
import com.roommate.hub.repository.UserPreferenceRepository;
import com.roommate.hub.repository.UserRepository;
import com.roommate.hub.util.DistrictNames;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.Locale;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserPreferenceRepository preferenceRepository;
    private final UserRepository userRepository;
    private final BlockedUserRepository blockedUserRepository;

    @Transactional
    public UserResponseDTO updateUserInfo(Long userId, String fullName, String phone,
            String gender, LocalDate birthDate, String university, String bioNote) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new com.roommate.hub.exception.ResourceNotFoundException("Người dùng không tồn tại!"));
        String normalizedName = fullName.trim();
        String normalizedGender = gender.toUpperCase(Locale.ROOT);
        String normalizedUniversity = university == null ? null : university.trim();
        if (normalizedName.isEmpty() || normalizedName.length() > 100) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Họ và tên không hợp lệ");
        }
        if (phone.length() > 20 || !(normalizedGender.equals("MALE") || normalizedGender.equals("FEMALE"))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thông tin hồ sơ không hợp lệ");
        }
        if (birthDate != null && birthDate.isAfter(LocalDate.now().minusYears(18))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Người dùng phải đủ 18 tuổi");
        }
        if (normalizedUniversity != null
                && (normalizedUniversity.isEmpty() || normalizedUniversity.length() > 150)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Trường đại học không hợp lệ");
        }
        UserPreference pref = bioNote == null ? null : preferenceRepository.findByUserId(userId).orElse(null);
        if (bioNote != null && !bioNote.isBlank() && pref == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hãy thiết lập tiêu chí trước khi thêm giới thiệu");
        }

        // Validate everything first; profile and biography are saved in one transaction.
        user.setFullName(normalizedName);
        user.setPhone(phone);
        user.setGender(normalizedGender);
        if (birthDate != null) user.setBirthDate(birthDate);
        if (normalizedUniversity != null) user.setUniversity(normalizedUniversity);
        if (pref != null) {
            // The survey stores metadata in the leading bracketed line. Edit only its note.
            String existing = pref.getBioDescription();
            var metadata = Pattern.compile("^\\[(.*?)\\](?:\\n(.*))?$", Pattern.DOTALL)
                    .matcher(existing == null ? "" : existing);
            String note = bioNote.trim();
            pref.setBioDescription(metadata.matches() ? "[" + metadata.group(1) + "]"
                    + (note.isEmpty() ? "" : "\n" + note) : note);
            preferenceRepository.save(pref);
        }
        return UserResponseDTO.from(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public PublicProfileResponseDTO getPublicProfile(Long userId) {
        User viewer = currentViewer();
        User user = userRepository.findById(userId)
                .filter(candidate -> "ACTIVE".equalsIgnoreCase(candidate.getStatus()) && candidate.isSearchActive())
                .orElseThrow(() -> new com.roommate.hub.exception.ResourceNotFoundException("Hồ sơ không còn công khai"));
        if (blockedUserRepository.existsByUserIdAndBlockedUserId(viewer.getId(), userId)
                || blockedUserRepository.existsByUserIdAndBlockedUserId(userId, viewer.getId())) {
            throw new ForbiddenException("Không thể xem hồ sơ vì hai người đã chặn nhau!");
        }
        UserPreference pref = preferenceRepository.findByUserId(userId).orElse(null);
        return PublicProfileResponseDTO.builder()
                .userId(user.getId()).fullName(user.getFullName()).avatarUrl(user.getAvatarUrl()).university(user.getUniversity())
                .targetDistrict(pref == null ? null : DistrictNames.canonical(pref.getTargetDistrict()))
                .budgetMin(pref == null ? null : pref.getBudgetMin()).budgetMax(pref == null ? null : pref.getBudgetMax())
                .sleepHabit(pref == null ? null : pref.getSleepHabit()).cleanlinessLevel(pref == null ? null : pref.getCleanlinessLevel())
                .isSmoking(pref == null ? null : pref.getIsSmoking()).allowPets(pref == null ? null : pref.getAllowPets())
                .bioDescription(pref == null ? null : pref.getBioDescription()).build();
    }

    private User currentViewer() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Bạn cần đăng nhập để xem hồ sơ!");
        }
        return userRepository.findByEmail(auth.getName())
                .filter(user -> "ACTIVE".equalsIgnoreCase(user.getStatus()))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Phiên đăng nhập không hợp lệ!"));
    }

    public UserPreferenceDTO getPreferences(Long userId) {
        UserPreference pref = preferenceRepository.findByUserId(userId)
                .orElse(null);

        if (pref == null) {
            return null;
        }

        return UserPreferenceDTO.builder()
                .targetDistrict(DistrictNames.canonical(pref.getTargetDistrict()))
                .budgetAmount(pref.getBudgetAmount())
                .budgetMin(pref.getBudgetMin()).budgetMax(pref.getBudgetMax())
                .targetGender(pref.getTargetGender()).topPriority(pref.getTopPriority())
                .moveInDate(pref.getMoveInDate()).roomType(pref.getRoomType())
                .workSchedule(pref.getWorkSchedule()).personalValue(pref.getPersonalValue())
                .sleepHabit(pref.getSleepHabit())
                .cleanlinessLevel(pref.getCleanlinessLevel())
                .isSmoking(pref.getIsSmoking())
                .allowPets(pref.getAllowPets())
                .bioDescription(pref.getBioDescription())
                .build();
    }

    @Transactional
    public UserPreferenceDTO saveOrUpdatePreferences(Long userId, UserPreferenceDTO dto) {
        if ((dto.getBudgetAmount() != null && !Double.isFinite(dto.getBudgetAmount()))
                || (dto.getBudgetMin() != null && !Double.isFinite(dto.getBudgetMin()))
                || (dto.getBudgetMax() != null && !Double.isFinite(dto.getBudgetMax()))) {
            throw new IllegalArgumentException("Ngân sách phải là số hữu hạn");
        }
        if ((dto.getBudgetMin() == null) != (dto.getBudgetMax() == null)
                || (dto.getBudgetMin() != null && dto.getBudgetMin() > dto.getBudgetMax())) {
            throw new IllegalArgumentException("Khoảng ngân sách không hợp lệ");
        }
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại!"));

        UserPreference pref = preferenceRepository.findByUserId(userId)
                .orElse(UserPreference.builder().user(user).build());

        dto.setTargetDistrict(DistrictNames.canonical(dto.getTargetDistrict()));
        pref.setTargetDistrict(dto.getTargetDistrict());
        pref.setBudgetAmount(dto.getBudgetAmount());
        pref.setBudgetMin(dto.getBudgetMin()); pref.setBudgetMax(dto.getBudgetMax());
        pref.setTargetGender(dto.getTargetGender()); pref.setTopPriority(dto.getTopPriority());
        pref.setSleepHabit(dto.getSleepHabit());
        pref.setCleanlinessLevel(dto.getCleanlinessLevel());
        pref.setIsSmoking(dto.getIsSmoking());
        pref.setAllowPets(dto.getAllowPets());
        pref.setBioDescription(dto.getBioDescription());

        // Older clients omit these optional fields. Do not erase saved choices.
        if (dto.getMoveInDate() != null) pref.setMoveInDate(dto.getMoveInDate());
        if (dto.getRoomType() != null) pref.setRoomType(dto.getRoomType());
        if (dto.getWorkSchedule() != null) pref.setWorkSchedule(dto.getWorkSchedule());
        if (dto.getPersonalValue() != null) pref.setPersonalValue(dto.getPersonalValue());

        preferenceRepository.save(pref);
        return getPreferences(userId);
    }
}
