#include <verilated.h>

#include <iostream>
#include <memory>
#include <string>
#include <fstream>
#include <iomanip>

#include "Vtop.h"
#include "test/test.h"

const unsigned int MAX_SIM_TIME = 10000;
int total_cycle = 0;

void print_pvs(const std::unique_ptr<Vtop>& cp) {
    using std::cout;
    using std::endl;
    using std::setw;
    using std::setfill;
    using std::string;
    using std::stringstream;
    using std::hex;
    using std::bitset;
    using std::left;

    string reg_hex;
    stringstream reg_value;

    cout << "Cycle: " << total_cycle << endl;
    cout << left << setw(8) << "is_halted: " << bitset<1>(cp->is_halted) << endl;
    cout << left << setw(8) << "Register outputs" << endl;
    for(int i = 0; i < 32; i++) {
        reg_value << setw(8) << setfill('0') << hex << cp->print_reg[i];
        reg_hex = reg_value.str();
        reg_value.str("");

        cout << setw(2) << i << " " << reg_hex << endl;;
    }

    return;
}

int main(int argc, char** argv, char** env) {
    using std::string;
    using std::unique_ptr;
    using std::cin;

    Verilated::commandArgs(argc, argv);
    const unique_ptr<Vtop> cp{new Vtop};

    cp->clk = 1;
    cp->reset = 1;
    next_cycle<Vtop>(cp);
    cp->reset = 0;

    while(total_cycle < MAX_SIM_TIME) {
        next_cycle<Vtop>(cp);
        total_cycle++;
        print_pvs(cp);
        cin.get();

        if(cp->is_halted == 1)
            break;
    }

    return 0;
}