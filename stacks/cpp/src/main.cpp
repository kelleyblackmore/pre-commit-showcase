#include <exception>
#include <iostream>
#include <optional>

#include "ring_buffer.h"

int main() {
  // clang-tidy's bugprone-exception-escape flags a `main` that can propagate an
  // exception, and it is right to: escaping main calls std::terminate, which
  // skips destructors and prints nothing useful. Everything below can throw -
  // the RingBuffer constructor rejects a zero capacity, and the allocation and
  // the stream operations have their own failure modes.
  try {
    showcase::RingBuffer<int> buffer(3);

    for (int value = 1; value <= 4; ++value) {
      const bool accepted = buffer.Push(value);
      std::cout << "push " << value << ": " << (accepted ? "ok" : "full") << '\n';
    }

    while (const std::optional<int> value = buffer.Pop()) {
      std::cout << "pop: " << *value << '\n';
    }
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << '\n';
    return 1;
  }

  return 0;
}
