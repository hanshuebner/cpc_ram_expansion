/* cpc_ram512k_v110
 *
 * Revised universal 464/6128 version, including pinout to go with cpc_ram_board_v110
 * 
 * CPLD module to implement all logic for a universal Amstrad CPC464/6128 512K RAM extension card
 *
 * (c) 2018, Revaldinho
 *
 * Select RAM bank scheme by writing to 0x7FXX with 0b11cccbbb, where:
 * 
 * ccc - picks one of 8 possible 64K banks
 * bbb - selects a block switching scheme within the chosen bank
 *       the actual block used for a RAM access is then selected by the top 2 addr bits for that access.
 *
 * 128K RAM Expansion Mapping Example...
 *
 * In the table below '-' indicates use of CPC internal RAM rather than the RAM expansion
 * -------------------------------------------------------------------------------------------------------------------------------
 * Address\cccbbb 000000 000001 000010 000011 000100 000101 000110 000011 001000 001001 001010 001011 001100 001101 001110 001111
 * -------------------------------------------------------------------------------------------------------------------------------
 * 1100-1111       -       3      3      3      -      -      -      -      -      7       7      7     -      -      -      -
 * 1000-1011       -       -      2      -      -      -      -      -      -      -       6      -     -      -      -      -
 * 0100-0111       -       -      1      -      0      1       2      3     -      -       5      -     4      5      6      7
 * 0000-0011       -       -      0      -      -      -      -      -      -      -       4      -     -      -      -      -
 * -------------------------------------------------------------------------------------------------------------------------------
 *
 */

module cpc_ram512k_v110  (
                    input        iorq_b,
                    input        ready,
                    input        ramrd_b,
                    input        clk,
                    input        adr9,
                    input        rfsh_b,
                    input        m1_b,
                    input        adr10,
                    output       ramcs_b,
                    input [7:0]  data,
                    input        reset_b,
                    input        wr_b,
                    input        rd_b,

                    inout        mreq_b,
                    inout        ramdis,
                    inout [1:0]  gpio,
                    inout [1:0]  dip,
                        
                    inout        adr15,
                    inout        adr14,

                    output [4:0] ramadrhi,
                    output       ramwe_b                    
                    );

  reg [7:0]        ramblock_q;
  reg [4:0]        ramadrhi_r;
  reg              ramcs_b_r;
  reg              clken_lat_qb;
  reg [5:0]        hibit_tmp_r;
  reg              adr15_q;
  reg              adr14_q;  
  reg              mreq_b_q;

  reg              overdrive_hi_q ;  
  reg              overdrive_lo_q ;
  
  wire             mode464   = dip[0];
  wire             overdrive = dip[1];    
  wire             shadowhi  = 1'b0;  // possibly another option for 464 mode (or replace overdrive)   
  wire [2:0]       shadow_bank = { shadowhi,2'b11};    
  
  // Create negedge clock on IO write event - clock low pulse will be suppressed if not an IOWR* event
  // but if the pulse is allowed through use the trailing (rising) edge to capture data
  wire             wclk    = !(clk|clken_lat_qb); 
  // Combination of RAMCS and RAMRD determine whether RAM output is enabled
  assign ramoe_b = ramrd_b;		
  assign ramwe_b = wr_b ;  
  assign ramcs_b = ramcs_b_r | mreq_b ;
  assign ramdis  = !ramcs_b_r ;    
  assign ramadrhi = ramadrhi_r ;
  assign dip = 2'bzz;
  assign gpio = 2'bzz;
  
  // Overdrive signals only in 464 mode if at all
  assign mreq_b = 1'bz;  
  assign adr15  = (overdrive_hi_q & !mreq_b ) ?1'b1: 
                  (overdrive_lo_q & !mreq_b ) ?1'b0: 
                  1'bz ;  
  assign adr14  = (overdrive_lo_q & !mreq_b  ) ?1'b0: 
                  1'bz ;  



  // Logic to compute overdrive state will not be used in 6128 mode
  always @ (negedge reset_b or posedge clk ) 
    if ( !reset_b ) begin
      overdrive_hi_q <= 1'b0;       
      overdrive_lo_q <= 1'b0;
    end
    else begin
      // Reset overdrive signals to 0 on inactive MREQ or always in 6128 mode
      if ( mreq_b | !mode464) begin  
        overdrive_hi_q <= 1'b0;         
        overdrive_lo_q <= 1'b0;
      end
      // Sample only if the overdrive DIP is set and its the first cycle of a memory access
      else if (overdrive & mreq_b_q) begin 
        // Redirect bank &4000 -> &C000 (screen)  only in mode 3 block 01 access        
        overdrive_hi_q <= (ramblock_q[2:0] == 3'b011) & ({adr15_q,adr14_q}==2'b01);                   
        // Redirect bank &C000 -> &0000  to avoid screen corruption in mode C1,2&3 and from &4000 -> &0000 in modes C4-7 (ie if screen relocated and overlaps extension RAM)!        
        overdrive_lo_q <= ((ramblock_q[2:0] == 3'b011) & (adr15_q & adr14_q)) | // Map all internal access to &C000 to &0000 in mode 3
                          ((ramblock_q[2:0] == 3'b001) & (adr15_q & adr14_q)) | // Map all internal access to &C000 to &0000 in mode 1
                          (ramblock_q[2:0] == 3'b010) |              // Map all internal access to &0000 in mode 2    
                          (ramblock_q[2] & ( !adr15_q & adr14_q)) ;  // Map &4000 -> &0000 in modes 4-7, protect screen if at &4000 when accessing external bank
      end
    end  

   always @ (negedge reset_b or posedge clk ) 
     if ( !reset_b ) begin
       mreq_b_q <= 1'b1;
     end
     else begin
       mreq_b_q <= mreq_b;
     end

   always @ (negedge reset_b or negedge mreq_b ) 
     if ( !reset_b ) begin
       adr15_q <= 1'b0;
       adr14_q <= 1'b0;       
     end
     else begin
       adr15_q <= adr15;
       adr14_q <= adr14;       
     end
  
  always @ ( clk )
    if ( clk ) begin
      clken_lat_qb <= !(!iorq_b && !wr_b && !adr15 && data[6] && data[7]);
    end
  
  always @ (negedge reset_b or posedge wclk )
    if (!reset_b)
      ramblock_q <= 8'b0;
    else
      ramblock_q <= { adr10, adr9, data[5:0]};

  always @ ( * )
    begin
      hibit_tmp_r = ramblock_q[5:0];       
      if ( (ramblock_q[5:3] == shadow_bank) & mode464 ) // Shadow bank active only in the 464
        hibit_tmp_r[5:3] =   (shadow_bank) & 3'b110; // alias the even bank below shadow bank to the shadow bank
      case (hibit_tmp_r[2:0])
	3'b000: {ramcs_b_r, ramadrhi_r} = { !mode464, shadow_bank, adr15, adr14_q };
	3'b001: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14_q}==2'b11 ) ? {1'b0, hibit_tmp_r[5:3],2'b11} : { !mode464, shadow_bank, adr15_q, adr14_q };
	3'b010: {ramcs_b_r, ramadrhi_r} = { 1'b0,hibit_tmp_r[5:3],adr15_q,adr14_q} ; 
	// Mode 3: Map 0b1100 to New 0b1100 _and_ 0b0100 to 0b1100 but in 'shadow' bank only 
	3'b011: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14_q}==2'b11 ) ? {1'b0,hibit_tmp_r[5:3],2'b11} : {!mode464, shadow_bank, (adr15_q|adr14_q), adr14_q };
	3'b100: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14_q}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],2'b00} : {!mode464, shadow_bank, adr15_q, adr14_q };              
	3'b101: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14_q}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],2'b01} : {!mode464, shadow_bank, adr15_q, adr14_q };              
	3'b110: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14_q}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],2'b10} : {!mode464, shadow_bank, adr15_q, adr14_q };              
	3'b111: {ramcs_b_r, ramadrhi_r} = ( {adr15_q,adr14_q}==2'b01 ) ? {1'b0,hibit_tmp_r[5:3],2'b11} : {!mode464, shadow_bank, adr15_q, adr14_q };
      endcase // case (hibit_tmp_r[2:0])
    end // always @ ( * )  
endmodule