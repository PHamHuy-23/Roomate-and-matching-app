package com.roommate.hub.controller;

import com.roommate.hub.dto.ChatMessageDTO;
import com.roommate.hub.dto.SendMessageDTO;
import com.roommate.hub.service.ChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @PostMapping("/messages")
    public ResponseEntity<ChatMessageDTO> sendMessage(@Valid @RequestBody SendMessageDTO dto) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(chatService.sendMessage(dto));
    }

    @GetMapping("/messages/{partnerId}")
    public ResponseEntity<List<ChatMessageDTO>> getConversation(@PathVariable Long partnerId) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(chatService.getConversation(partnerId));
    }
}
