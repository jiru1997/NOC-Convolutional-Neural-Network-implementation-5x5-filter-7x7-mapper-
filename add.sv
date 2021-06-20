//-------------------------------------------------------------------------------------------------
// control center module 
// control initialization of all PEs 
//-------------------------------------------------------------------------------------------------

`timescale 1ns/1ps
import SystemVerilogCSP::*;
import dataformat::*;

module add
  #(parameter WIDTH = 4,
  parameter tot_num = 9,
  parameter tot_time = 5,
  parameter DATA_WIDTH = 18,
  parameter FL = 1,
  parameter BL = 1,
  parameter PACKDELAY = 1)

  ( input bit[WIDTH - 1:0] _index,
    input bit[WIDTH - 1:0] _mem_index,
    interface ccToAdd,
    interface RouterToAdd_in,
    interface RouterToAdd_out);

  int times[int];
  logic [tot_num - 1:0][8 * tot_time - 1:0] sumbank;
  int pointer, i;
  bit flag = 0;
  bit[WIDTH - 1:0] index;
  bit[WIDTH - 1:0] mem_index;
  bit[DATA_WIDTH - 1:0] data_pass_memory;               
  bit[DATA_WIDTH - 1:0] data_pass_PE;                  
  reg reset, aReq;
  wire bAck, bReq, flagop;
  logic [8 * tot_time - 1 : 0] data_in;
  wire [8 - 1 : 0] data_out, finalResult;

  sum s(.aReq(aReq), .data_in(data_in), .bAck(bAck), .reset(reset), .bReq(bReq), .data_out(data_out));
  data_bucket db (.data_in(data_out), .reset(reset), .aReq(bReq), .aAck(bAck), .data_out(finalResult), .flag(flagop));

  always begin
      RouterToAdd_in.Receive(data_pass_PE);
      sumbank[dataformater::getsendaddr(data_pass_PE)] += dataformater::unpackdata(data_pass_PE) << (8 * times[dataformater::getsendaddr(data_pass_PE)]);
      times[dataformater::getsendaddr(data_pass_PE)] += 1;
      #FL;
  end

  always begin
    wait(times[pointer] == tot_time);
    data_in = sumbank[pointer];
    aReq = ~aReq;
    @(flagop);
    #1;
    data_pass_memory = dataformater::packdata(index, mem_index, 0, finalResult);
	#PACKDELAY;
    pointer = pointer + 1;
    RouterToAdd_out.Send(data_pass_memory);
    #BL;
  end

  always begin
    wait(pointer == tot_num);
    ccToAdd.Send(flag);
    wait(1 == 0);
  end

  initial begin
    #0.1;
    pointer = 0;
    aReq = 0;
    index = _index;
    mem_index = _mem_index;
    for(i = 0; i < tot_num; i = i + 1) begin
      times[i] = 0;
      sumbank[i] = 0;
    end
    ccToAdd.Receive(flag);
	#FL;
  end

endmodule
