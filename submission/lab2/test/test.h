#include <verilated.h>

#include <memory>

template <typename T>
void next_cycle(const std::unique_ptr<T>& contextp) {
    contextp->clk ^= 1;
    contextp->eval();
    contextp->clk ^= 1;
    contextp->eval();
}