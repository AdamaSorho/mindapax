package com.adamasorho.mindapax_backend.dto.response;

import java.util.List;

import org.springframework.data.domain.Page;

import lombok.Data;

@Data
public class PageResponse<T> {
  private List<T> content;
  private int page;
  private int size;
  private long totalElements;
  private int totalPages;
  private boolean isLast;

  public PageResponse(Page<T> page) {
      this.content = page.getContent();
      this.page = page.getNumber();
      this.size = page.getSize();
      this.totalElements = page.getTotalElements();
      this.totalPages = page.getTotalPages();
      this.isLast = page.isLast();
  }

}

