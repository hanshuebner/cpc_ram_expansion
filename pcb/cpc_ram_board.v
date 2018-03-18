// 
// cpc_ram_board netlist
// 
// netlister.py format
// 
// (c) Revaldinho, 2018
// 
//  
module cpc_ram_board ();

  // wire declarations
  supply0 VSS;
  supply1 VDD_EXT;
  supply1 VDD_CPC;
  supply1 VDD;
  supply1 VDD3V3;

  wire Sound;  
  wire A15,A14,A13,A12,A11,A10,A9,A8,A7,A6,A5,A4,A3,A2,A1,A0 ;
  wire D7,D6,D5,D4,D3,D2,D1,D0 ;
  wire MREQ_B;  
  wire M1_B;
  wire RFSH_B;
  wire IOREQ_B;
  wire RD_B;
  wire WR_B;
  wire HALT_B;
  wire INT_B ;
  wire NMI_B ;
  wire BUSRQ_B;  
  wire BUSACK_B;
  wire READY;
  wire BUSRESET_B;
  wire RESET_B;
  wire ROMEN_B;
  wire ROMDIS ;
  wire RAMRD_B;
  wire RAMDIS;
  wire CURSOR;
  wire LPEN;
  wire EXP_B;
  wire CLK;
  wire RAMCS_B;
  wire HIADR4,HIADR3,HIADR2,HIADR1,HIADR0;

  wire TMS;
  wire TDI;
  wire TDO;
  wire TCK;
  
  // 3 pin header with link to use either CPC or external 5V power for the board
  hdr1x03      L1 (
                   .p1(VDD_CPC),
                   .p2(VDD),
                   .p3(VDD_EXT)
                   );

  // 3 pin Tabbed power connector for external 5V power
  powerheader3   CONN0 (
                        .vdd1(VDD_EXT),
                        .vdd2(VDD_EXT),
                        .gnd(VSS)
                        );

  MCP1700_3302E   REG3V3 (
                            .vin(VDD),
                            .gnd(VSS),
                            .vout(VDD3V3)
                            );


  // Radial electolytic, one per board on the main 5V supply
  cap22uf CAP22UF_0(.minus(VSS),.plus(VDD));

  // Two ceramic caps to be placed v. close to regulator pins
  cap1uf          reg_cap0 (.p0(VDD), .p1(VSS));
  cap1uf          reg_cap1 (.p0(VDD3V3), .p1(VSS));

  // Amstrad CPC Edge Connector
  idc_hdr_50w  CONN1 (
                      .p50(Sound),   .p49(VSS),
                      .p48(A15),     .p47(A14),
                      .p46(A13),     .p45(A12),
                      .p44(A11),     .p43(A10),
                      .p42(A9),      .p41(A8)
                      .p40(A7),      .p39(A6),
                      .p38(A5),      .p37(A4),
                      .p36(A3),      .p35(A2),
                      .p34(A1),      .p33(A0),
                      .p32(D7),      .p31(D6)
                      .p30(D5),      .p29(D4),
                      .p28(D3),      .p27(D2),
                      .p26(D1),      .p25(D0),
                      .p24(VDD_CPC), .p23(MREQ_B),
                      .p22(M1_B),    .p21(RFSH_B),
                      .p20(IOREQ_B), .p19(RD_B),
                      .p18(WR_B),    .p17(HALT_B),
                      .p16(INT_B),   .p15(NMI_B),
                      .p14(BUSRQ_B), .p13(BUSACK_B),
                      .p12(READY),   .p11(BUSRESET_B),
                      .p10(RESET_B), .p9(ROMEN_B),
                      .p8(ROMDIS),   .p7(RAMRD_B),
                      .p6(RAMDIS),   .p5(CURSOR),
                      .p4(LPEN),     .p3(EXP_B),
                      .p2(VSS),      .p1(CLK),
                      ) ;

  // Standard layout JTAG port for programming the CPLD
  hdr8way JTAG (
                .p1(VSS),  .p2(VSS),
                .p3(TMS),  .p4(TDI),
                .p5(TDO),  .p6(TCK),
                .p7(VDD),  .p8(),
                );

  // 9572XL CPLD - 3.3V core, 5V IO
  xc9572pc44  CPLD (
                    .p1(MREQ_B),
	            .p2(IOREQ_B),
	            .p3(WR_B),
	            .p4(RAMRD_B),
	            .gck1(CLK),
	            .gck2(RAMCS_B),
	            .gck3(RD_B),
	            .p8(HIADR4),
	            .p9(HIADR3),
	            .gnd1(VSS),
	            .p11(HIADR2),
	            .p12(HIADR1),
	            .p13(HIADR0),
	            .p14(A13),
	            .tdi(TDI),
	            .tms(TMS),
	            .tck(TCK),
	            .p18(D7),
	            .p19(D6),
	            .p20(D5),
	            .vccint1(VDD3V3),
	            .p22(D4),
	            .gnd2(VSS),
	            .p24(D3),
	            .p25(D2),
	            .p26(D1),
	            .p27(D0),
	            .p28(READY),
	            .p29(RAMDIS),
	            .tdo(TDO),
	            .gnd3(VSS),
	            .vccio(VDD),
	            .p33(),
	            .p34(),
	            .p35(),
	            .p36(),
	            .p37(),
	            .p38(),
	            .gsr(RESET_B),
	            .gts2(),
	            .vccint2(VDD3V3),
	            .gts1(),
	            .p43(A15),
	            .p44(A14),
                    );

  // Alliance 512K x 8 SRAM
  bs62lv4006  SRAM (
                    .a18(HIADR4),  .vcc(VDD),
                    .a16(HIADR2),  .a15(HIADR1),
                    .a14(HIADR0),  .a17(HIADR3),
                    .a12(A12),  .web(WR_B),
                    .a7(A7),  .a13(A13),
                    .a6(A6),  .a8(A8),
                    .a5(A5),  .a9(A9),
                    .a4(A4),  .a11(A11),
                    .a3(A3),  .oeb(RAMRD_B),
                    .a2(A2),  .a10(A10),
                    .a1(A1),  .csb(RAMCS_B),
                    .a0(A0),  .d7(D7),
                    .d0(D0),  .d6(D6),
                    .d1(D1),  .d5(D5),
                    .d2(D2),  .d4(D4),
                    .vss(VSS),  .d3(D3)
                    );

   // Decoupling caps for CPLD and one for SRAM
   cap100nf CAP100N_1 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_2 (.p0( VSS ), .p1( VDD ));
   cap100nf CAP100N_3 (.p0( VSS ), .p1( VDD3V3 ));

endmodule