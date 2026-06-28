package com.app.crud.controller;

import com.app.crud.dto.ApiResponse;
import com.app.crud.dto.ItemDto;
import com.app.crud.service.ItemService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/items")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class ItemController {

    private final ItemService itemService;

    // POST /api/items
    @PostMapping
    public ResponseEntity<ApiResponse<ItemDto.Response>> create(
            @Valid @RequestBody ItemDto.Request request) {
        ItemDto.Response created = itemService.create(request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Item created successfully", created));
    }

    // GET /api/items
    @GetMapping
    public ResponseEntity<ApiResponse<List<ItemDto.Response>>> getAll() {
        return ResponseEntity.ok(ApiResponse.ok(itemService.findAll()));
    }

    // GET /api/items/{id}
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ItemDto.Response>> getById(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.ok(itemService.findById(id)));
    }

    // PUT /api/items/{id}
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ItemDto.Response>> update(
            @PathVariable Long id,
            @Valid @RequestBody ItemDto.Request request) {
        return ResponseEntity.ok(ApiResponse.ok("Item updated successfully", itemService.update(id, request)));
    }

    // DELETE /api/items/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
        itemService.delete(id);
        return ResponseEntity.ok(ApiResponse.ok("Item deleted successfully", null));
    }

    // GET /api/items/search?q=...
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<List<ItemDto.Response>>> search(
            @RequestParam(name = "q", defaultValue = "") String query) {
        return ResponseEntity.ok(ApiResponse.ok(itemService.search(query)));
    }
}
