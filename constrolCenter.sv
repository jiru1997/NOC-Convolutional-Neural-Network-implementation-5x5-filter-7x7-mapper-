//-------------------------------------------------------------------------------------------------
// control center module 
// control initialization of all PEs 
//-------------------------------------------------------------------------------------------------

`timescale 1ns/1ps
import SystemVerilogCSP::*;

module system_control

  #(parameter FL = 1,
  parameter BL = 1)

  ( interface ccToPE0,
    interface ccToPE1,
    interface ccToPE2,
    interface ccToPE3,
    interface ccToPE4,
    interface ccToAdd,
    interface ccToMem,
    interface start,
    interface done);

  bit flag = 0;
  int fpt;
    
  initial begin
    fpt = $fopen("transcript.dump");
    start.Receive(flag);
    $fwrite(fpt,"%m start token received at %t \n",$realtime);
	#FL;
    fork
      ccToMem.Send(flag);
      ccToPE0.Send(flag);
      ccToPE1.Send(flag);
      ccToPE2.Send(flag);
      ccToPE3.Send(flag);
      ccToPE4.Send(flag);
      ccToAdd.Send(flag);
    join
	#BL;
    fork
      ccToPE0.Receive(flag);
      ccToPE1.Receive(flag);
      ccToPE2.Receive(flag);
      ccToPE3.Receive(flag);
      ccToPE4.Receive(flag);
      ccToAdd.Receive(flag);
      ccToMem.Receive(flag);
    join
	#FL;
    done.Send(flag);
      $fwrite(fpt,"%m sent done token at %t \n",$realtime);
	#BL;
  end 



endmodule