package com.app.crud.service;

import com.app.crud.dto.ItemDto;
import com.app.crud.model.Item;
import com.app.crud.repository.ItemRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class ItemService {

    private final ItemRepository itemRepository;

    // ── CREATE ─────────────────────────────────────
    public ItemDto.Response create(ItemDto.Request request) {
        log.info("Creating item: {}", request.getName());
        Item item = Item.builder()
                .name(request.getName())
                .description(request.getDescription())
                .quantity(request.getQuantity())
                .build();
        return toResponse(itemRepository.save(item));
    }

    // ── READ ALL ───────────────────────────────────
    @Transactional(readOnly = true)
    public List<ItemDto.Response> findAll() {
        return itemRepository.findAll()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ── READ ONE ───────────────────────────────────
    @Transactional(readOnly = true)
    public ItemDto.Response findById(Long id) {
        return toResponse(getOrThrow(id));
    }

    // ── UPDATE ─────────────────────────────────────
    public ItemDto.Response update(Long id, ItemDto.Request request) {
        log.info("Updating item id={}", id);
        Item item = getOrThrow(id);
        item.setName(request.getName());
        item.setDescription(request.getDescription());
        item.setQuantity(request.getQuantity());
        return toResponse(itemRepository.save(item));
    }

    // ── DELETE ─────────────────────────────────────
    public void delete(Long id) {
        log.info("Deleting item id={}", id);
        if (!itemRepository.existsById(id)) {
            throw new EntityNotFoundException("Item not found with id: " + id);
        }
        itemRepository.deleteById(id);
    }

    // ── SEARCH ─────────────────────────────────────
    @Transactional(readOnly = true)
    public List<ItemDto.Response> search(String query) {
        return itemRepository.searchByNameOrDescription(query)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    // ── helpers ───────────────────────────────────
    private Item getOrThrow(Long id) {
        return itemRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Item not found with id: " + id));
    }

    private ItemDto.Response toResponse(Item item) {
        return ItemDto.Response.builder()
                .id(item.getId())
                .name(item.getName())
                .description(item.getDescription())
                .quantity(item.getQuantity())
                .createdAt(item.getCreatedAt())
                .updatedAt(item.getUpdatedAt())
                .build();
    }
}
