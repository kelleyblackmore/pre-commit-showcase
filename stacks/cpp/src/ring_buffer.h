#pragma once

#include <cstddef>
#include <optional>
#include <stdexcept>
#include <vector>

namespace showcase {

// Fixed-capacity FIFO queue backed by a contiguous buffer.
//
// Exists so the C++ hooks have something with real structure to inspect:
// clang-format checks the layout and include ordering, cpplint the style, and
// clang-tidy (manual stage) the semantics.
template <typename T>
class RingBuffer {
 public:
  explicit RingBuffer(std::size_t capacity) : buffer_(capacity) {
    if (capacity == 0) {
      throw std::invalid_argument("RingBuffer capacity must be greater than zero");
    }
  }

  bool Push(const T& value) {
    if (size_ == buffer_.size()) {
      return false;
    }
    buffer_[tail_] = value;
    tail_ = (tail_ + 1) % buffer_.size();
    ++size_;
    return true;
  }

  std::optional<T> Pop() {
    if (size_ == 0) {
      return std::nullopt;
    }
    T value = buffer_[head_];
    head_ = (head_ + 1) % buffer_.size();
    --size_;
    return value;
  }

  std::size_t size() const { return size_; }

  std::size_t capacity() const { return buffer_.size(); }

  bool empty() const { return size_ == 0; }

 private:
  std::vector<T> buffer_;
  std::size_t head_ = 0;
  std::size_t tail_ = 0;
  std::size_t size_ = 0;
};

}  // namespace showcase
