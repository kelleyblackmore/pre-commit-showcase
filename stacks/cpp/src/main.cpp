#include <iostream>

#include "ring_buffer.h"

int main() {
  showcase::RingBuffer<int> buffer(3);

  for (int value = 1; value <= 4; ++value) {
    const bool accepted = buffer.Push(value);
    std::cout << "push " << value << ": " << (accepted ? "ok" : "full") << '\n';
  }

  while (const std::optional<int> value = buffer.Pop()) {
    std::cout << "pop: " << *value << '\n';
  }

  return 0;
}
