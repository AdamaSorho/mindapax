package com.adamasorho.mindapax_backend.controller;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.adamasorho.mindapax_backend.dto.UserDTO;
import com.adamasorho.mindapax_backend.dto.request.AuthRequest;
import com.adamasorho.mindapax_backend.dto.response.PageResponse;
import com.adamasorho.mindapax_backend.mapper.UserMapper;
import com.adamasorho.mindapax_backend.model.User;
import com.adamasorho.mindapax_backend.service.UserService;

import lombok.AllArgsConstructor;

@RestController
@RequestMapping("/api/v1/users")
@AllArgsConstructor
public class UserController {
  private final UserService userService;
  private final UserMapper userMapper;

    @PostMapping
    public ResponseEntity<UserDTO> createUser(@RequestBody AuthRequest authRequest) {
        User user = userMapper.toEntity(authRequest);

        return ResponseEntity.ok(userMapper.toDTO(userService.createUser(user)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<UserDTO> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(userMapper.toDTO(userService.getUserById(id)));
    }

    @GetMapping
    public ResponseEntity<PageResponse<UserDTO>> getUsers(@PageableDefault(size = 10) Pageable pageable) {
        return ResponseEntity.ok(
            new PageResponse<UserDTO>(
                userService.getUsers(pageable).map(userMapper::toDTO)
            )
        );
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> updateUser(@PathVariable Long id, @RequestBody UserDTO userDTO) {
        User user = userMapper.toEntity(userDTO);

        return ResponseEntity.ok(userMapper.toDTO(userService.updateUser(id, user)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        userService.deleteUser(id);

        return ResponseEntity.noContent().build();
    }
}
