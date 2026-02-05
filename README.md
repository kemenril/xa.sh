## xa.sh, a cross-assembler written in a Bourne shell script

An entire assembler in a shell script.  It uses a simple system for writing binaries, based on the POSIX printf statement.  It does numeric conversions using **sed** and **dc**, and inline math using **expr**.  It handles something like the standard *Intel* assembly syntax -- with some limitations -- by preprocessing the source into something that looks enough like a shell script and importing a set of functions corresponding to various CPU instructions in the target architecture.  It currently implements an 8080 core.  Assembly is done using a standard two-pass model; the symbol table is written into shell variables on the first pass, and used to generate correct code on the second.

As it stands, the whole thing is a bit over a thousand lines of shell code, in eighty-some files.  It's fairly modular, and will load different machine cores on command, so given a bit more work, it can target multiple architectures.  6502 and 6809 are likely candidates, as are Z80 and 8085 extensions to the 8080 instruction set.

### But why?

Because it's hilarious.  Also because I can.  Maybe there's some commentary in there about how a tool can be used to do jobs it's not intended to do, or about the amount of power available in a standard Unix shell, but mostly it amuses me.  I just hope it doesn't somehow become another **Electron**.

### Requirements

I would think the only hard requirement is something like Unix from the nineties or later.  The **printf** shell command is required, as are **awk**, **sed**, **wc**, **dc**, and a Bourne-compatible shell.  Definitely runs and works on Linux and Mac OSX at the moment.

### Repository layout

The repository is organized in the same way the script wants the files organized on your disk.  The main script is in **bin/xa.sh**, the main supporting code is in **lib/xa.sh/common**, and the instruction maps are in **lib/xa.sh/core**.  Some simple example code is in **examples**.

### Installation

It's a shell script.  Dump it somewhere on a Unix system and make sure **xa.sh** is executable.  You can probably run it right out of a clone of the repository.  By default the script expects to be in a directory *<somewhere/bin>*, relative to which there is a *<somewhere>/lib/xa.sh>* directory with all the supporting bits and pieces.  You can put it in its own directory and run it in place, or you can dump the library directory in */usr/local/lib* and the binary into */usr/local/bin* -- something like that.

### Usage

From the built-in help:

      xa.sh: An assembler in Bourne.

        Usage:
          xa.sh [<-a|-m|--arch|--machine> <ARCH>][-d|--debug][-s|--stream] <INPUT> [OUTPUT]

        Options:
          -a | --arch | -m | --machine  <ARCH>
            Generate code for <ARCH>, in case multiple architectures are 
          available.

          -d | --debug        
            If this option is present, print extra debugging infomation to
          stderr.	

          -s | --stream       
            Write output to STDOUT, rather than to a file.


In the simplest case, just give it an input file, and it will generate a.bin as output, or give it the *-s* switch, and it will write to *STDOUT*.

    $ cat examples/loop-8080.asm 
    
            ORG	0100H
            MVI	A, 1
    LOOP:   INR	A
            CPI	5
            JNZ	LOOP
    
    $ xa.sh examples/loop-8080.asm -s|hexdump -C
    Utility module loaded.
    Load /tmp/xa.sh/lib/xa.sh/common/bytes
    Load /tmp/xa.sh/lib/xa.sh/common/params
    Load /tmp/xa.sh/lib/xa.sh/common/memory
    Load /tmp/xa.sh/lib/xa.sh/common/preprocess
    Architecture: 8080
    Instructions: ACI ADC ADD ADI ANA ANI CALL CC CM CMA CMC CMP CNC CNZ CP CPE CPI CPO CZ DAA DAD DCR DCX DI EI HLT IN INR INX JC JM JMP JNC JNZ JP JPE JPO JZ LDA LDAX LHLD LXI MOV MVI NOP ORA ORI OUT PCHL POP PUSH RAL RAR RC RET RLC RM RNC RNZ RP RPE RPO RRC RST RZ SBB SBI SHLD SPHL STA STAX STC SUB SUI XCHG XRA XRI XTHL
    Assemble examples/loop-8080.asm -> STDOUT
    00000000  3e 01 3c fe 05 c2 02 01                           |>.<.....|
    00000008

    

### Syntax quirks

Processing of input files is not the most robust thing.  There are a few quirks, and support for standard syntax is not perfect.  Keep the following things in mind:

   * Because the assembly source is evaluated by the shell, hexadecimal numbers using a notation in the style of $0ABC will likely not work without some escaping.  You can use a notation in the form of 0ABCh or 0xABCD instead, which is more shell-safe.
   * Because *expr* is used to handle inline math, spacing between identifiers and numbers and operations is required.  **MVI A, LOOP+4** will likely not work, but **MVI A, LOOP + 4** probably will.  In fact, if we're being honest, the comma is accepted between arguments because it's conventional, but it is mostly ignored.  The first argument is often a simple register designation or the like, and is easy to differentiate from everything else.
   * Because it's a wildcard in the shell, the use of * to set and get the value of the PC is not implemented.  You can use *ORG* to set the counter and *PC* to get its current value, which avoids expansion-related trouble.
   * Labels are global and should not be redefined.  If you redefine a label, all references to that label will probably use the most recent definition.


