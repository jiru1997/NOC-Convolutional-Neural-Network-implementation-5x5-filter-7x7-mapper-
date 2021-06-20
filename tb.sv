//-------------------------------------------------------------------------------------------------
//  SystemVerilogCSP: testbench
//  University of Southern California
//-------------------------------------------------------------------------------------------------
`timescale 1ns/1fs
import SystemVerilogCSP::*;
import dataformat::*;

module ctrl_tb

 #(parameter WIDTH = 8,
 parameter DEPTH_I = 7,
 parameter WIDTH_I = 7,
 parameter ADDR_I = 8,
 parameter DEPTH_F = 5,
 parameter WIDTH_F = 5,
 parameter ADDR_F = 8,
 parameter DEPTH_R = 3,
 parameter WIDTH_R = 3,
 parameter READ_FINAL_F_MAP = 0)

 (interface mem_data, 
  interface mem_addr,
  interface datain_filter, 
  interface addrin_filter,
  interface start,
  interface done,
  interface result_addr,
  interface result_data,
  output reg reset);
 
 logic d;
 bit don_e;
 logic [WIDTH - 1:0] data_ifmap, data_filter, res;
 logic [ADDR_F-1:0] addr_filter = 0;
 logic [ADDR_I-1:0] addr_ifmap = 0;
 logic [WIDTH-1:0] psum_o;
 logic [WIDTH-1:0] comp[DEPTH_R*WIDTH_R-1:0];
 integer count, error_count, fpo, fpt, fpi_f, fpi_i, fpi_r,status = 0;

 initial begin
   $timeformat(-9, 2, " ns");
   reset = 0;
   fpi_f = $fopen("filter.txt","r");
   fpi_i = $fopen("ifmap.txt","r");
   fpi_r = $fopen("golden_result.txt","r");
   fpo = $fopen("test.dump","w");
   fpt = $fopen("transcript.dump");
   if(!fpi_f || !fpi_i) begin
       $display("A file cannot be opened!");
       $stop;
   end
   for(integer i=0; i<(DEPTH_F*WIDTH_F); i++) begin
	    if(!$feof(fpi_f)) begin
	     status = $fscanf(fpi_f,"%d\n", data_filter);
	     //$display("fpf data read:%d", data_filter);
	     addrin_filter.Send(addr_filter);
	     datain_filter.Send(data_filter); 
	     //$display("filter memory: mem[%d]= %d",addr_filter,data_filter);
	     addr_filter++;
	     //$display("addr_filter=%d",addr_filter);
	   end 
   end
   for(integer i=0; i<DEPTH_I*WIDTH_I; i++) begin
	    if (!$feof(fpi_i)) begin
	     status = $fscanf(fpi_i,"%d\n", data_ifmap);
	     //$display("fpi data read:%d", data_ifmap);
	     mem_addr.Send(addr_ifmap);
	     mem_data.Send(data_ifmap); 
	     //$display("ifmap memory: mem[%d]= %d",addr_ifmap, data_ifmap);
	     addr_ifmap++;
	   end 
   end

   for(integer i=0; i<(DEPTH_R*WIDTH_R); i++) begin
	    if(!$feof(fpi_r)) begin
	     status = $fscanf(fpi_r,"%d\n", res);
	     //$display("fpi_r data read:%d", res);
	     comp[i] = res;
	     //$fdisplay(fpt,"comp[%d]= %d",i,res); 
	     //$display("comp[%d]= %d",i,res);
        end 
   end

	// starting the system
	#0.1;
    reset = 1;
	start.Send(0); 
	$fdisplay(fpt,"%m sent start token at %t",$realtime);
	$display("%m sent start token at %t",$realtime);
    #0.1;
    done.Receive(don_e);
    $fdisplay(fpt,"%m done token received at %t",$realtime);
    // comparing results
    error_count = 0;
    count = READ_FINAL_F_MAP;
    for(integer i=0; i<DEPTH_R*WIDTH_R; i++) begin
	  result_addr.Send(count);
	  count++;
	  result_data.Receive(res);
	  if (res !== comp[i])  begin
	   $fdisplay(fpo,"%d != %d error!",res,comp[i]);
	   $fdisplay(fpt,"%d != %d error!",res,comp[i]);
	   $display("%d != %d error!",res,comp[i]);
	   $fdisplay(fpt,"mem[%d] = %d == comp[%d] = %d",count, res, i, comp[i]);
	   $fdisplay(fpo,"mem[%d] = %d == comp[%d] = %d",count, res, i, comp[i]);
	   error_count++;
	  end 
	  else begin
	   $display(fpt,"mem[%d] = %d == comp[%d] = %d",count, res, i, comp[i]);
	   $fdisplay(fpo,"mem[%d] = %d == comp[%d] = %d",count, res, i, comp[i]);
	   $display("%m result value %0d: %d received at %t",i, res, $realtime);
	  end
	end
	$fdisplay(fpo,"total errors = %d",error_count);
	$fdisplay(fpt,"total errors = %d",error_count);
	$display("total errors = %d",error_count); 
 
	$display("%m Results compared, ending simulation at %t",$realtime);
	$fdisplay(fpt,"%m Results compared, ending simulation at %t",$realtime);
	$fdisplay(fpo,"%m Results compared, ending simulation at %t",$realtime);
	$fclose(fpt);
	$fclose(fpo);
	$stop;
 end
 
 // watchdog timer
 initial begin
	#10000;
	$display("*** Stopped by watchdog timer ***");
	$stop;
 end

endmodule // pe_tb

//testbench instantiation
module testbench;

 wire rst;

 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) addrin_mapper();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) addrin_filter();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) datain_filter();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) datain_mapper();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) result_addr();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(8)) result_data();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(18)) intf  [24:1] (); 
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToPE0 ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToPE1 ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToPE2 ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToPE3 ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToPE4 ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToMem ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  ccToAdd ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  start ();
 Channel #(.hsProtocol(P4PhaseBD), .WIDTH(1))  done ();

 ctrl_tb tb ( .reset(rst), .start(start), .mem_data(datain_mapper), .mem_addr(addrin_mapper),
    .result_data(result_data), .result_addr(result_addr), .done(done), .datain_filter(datain_filter), 
    .addrin_filter(addrin_filter));

 add ad(._index(4'b1101), ._mem_index(4'b0001), .RouterToAdd_in(intf[20]), .RouterToAdd_out(intf[19]), .ccToAdd(ccToAdd));

 system_control sys_ctrl(.ccToPE0(ccToPE0), .ccToPE1(ccToPE1), .ccToPE2(ccToPE2), .ccToPE3(ccToPE3), .ccToPE4(ccToPE4), .start(start), 
 	.done(done), .ccToAdd(ccToAdd), .ccToMem(ccToMem));

 memory memo(._index(4'b0001), .sys_addr_out(addrin_mapper), .sys_addr_in(addrin_filter), 
 	.sys_data_in(datain_filter), .sys_data_out(datain_mapper), .tb_addr_out(intf[1]), 
 	.tb_addr_in(intf[2]), .result_data(result_data), .result_addr(result_addr), .ccToMem(ccToMem));

 PE pe1(._index(4'b0011), ._inner_index(4'b0000), ._sum_index(4'b1101), 
  	._mem_index(4'b0001), ._next_pe_index(4'b0101), ._tot_pe_num(4'b0101), ._tot_round(4'b0011), ._filter_pointer(8'b00000000), ._ifmap_pointer(8'b00000000),
  	.RouterToPE_in(intf[4]), .RouterToPE_out(intf[3]), .ccToPE(ccToPE0));
 PE pe2(._index(4'b0101), ._inner_index(4'b0001), ._sum_index(4'b1101), 
 	._mem_index(4'b0001), ._next_pe_index(4'b0111), ._tot_pe_num(4'b0101), ._tot_round(4'b0011), ._filter_pointer(8'b00000101), ._ifmap_pointer(8'b00000111),
 	.RouterToPE_in(intf[12]), .RouterToPE_out(intf[11]), .ccToPE(ccToPE1));
 PE pe3(._index(4'b0111), ._inner_index(4'b0010), ._sum_index(4'b1101), 
  	._mem_index(4'b0001), ._next_pe_index(4'b1001), ._tot_pe_num(4'b0101), ._tot_round(4'b0011), ._filter_pointer(8'b00001010), ._ifmap_pointer(8'b00001110),
  	.RouterToPE_in(intf[14]), .RouterToPE_out(intf[13]), .ccToPE(ccToPE2));
 PE pe4(._index(4'b1001), ._inner_index(4'b0011), ._sum_index(4'b1101), 
 	._mem_index(4'b0001), ._next_pe_index(4'b1011), ._tot_pe_num(4'b0101), ._tot_round(4'b0011), ._filter_pointer(8'b00001111), ._ifmap_pointer(8'b00010101),
 	.RouterToPE_in(intf[22]), .RouterToPE_out(intf[21]), .ccToPE(ccToPE3));
 PE pe5(._index(4'b1011), ._inner_index(4'b0100), ._sum_index(4'b1101), 
 	._mem_index(4'b0001), ._next_pe_index(4'b0011), ._tot_pe_num(4'b0101), ._tot_round(4'b0011), ._filter_pointer(8'b00010100), ._ifmap_pointer(8'b00011100),
 	.RouterToPE_in(intf[24]), .RouterToPE_out(intf[23]), .ccToPE(ccToPE4));
 
 router #(.left_min(1), .right_max(3), .router_add(2)) r2 
 (.p_in(intf[6]), .p_out(intf[5]), .ch1_in(intf[1]), .ch1_out(intf[2]), .ch2_in(intf[3]), .ch2_out(intf[4]));
 router #(.left_min(1), .right_max(7), .router_add(4)) r4 
 (.p_in(intf[8]), .p_out(intf[7]), .ch1_in(intf[5]), .ch1_out(intf[6]), .ch2_in(intf[9]), .ch2_out(intf[10]));
 router #(.left_min(5), .right_max(7), .router_add(6)) r6 
 (.p_in(intf[10]), .p_out(intf[9]), .ch1_in(intf[11]), .ch1_out(intf[12]), .ch2_in(intf[13]), .ch2_out(intf[14]));
 router #(.left_min(9), .right_max(13), .router_add(12)) r12 
 (.p_in(intf[16]), .p_out(intf[15]), .ch1_in(intf[17]), .ch1_out(intf[18]), .ch2_in(intf[19]), .ch2_out(intf[20]));
 router #(.left_min(9), .right_max(11), .router_add(10)) r10 
 (.p_in(intf[18]), .p_out(intf[17]), .ch1_in(intf[21]), .ch1_out(intf[22]), .ch2_in(intf[23]), .ch2_out(intf[24]));
 router_top #(.router_add(8)) r8 
 (.ch1_in(intf[7]), .ch1_out(intf[8]), .ch2_in(intf[15]), .ch2_out(intf[16]));

endmodule
