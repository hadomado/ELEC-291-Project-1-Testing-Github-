
MCP3008_protocall MAC
	push acc ; save the three registers used (illegal to push r0, r1?)
	mov a, r0
	push acc
	mov a, r1
	push acc
	
	clr CE_ADC; slave select for MCP3008
	mov r0, #0x01 ; byte sent acording to mcp3008 data sheet figure 6-1
	lcall DO_SPI_G; send initial byte
	
	mov a, #0
	cjne a, #%0 , MCPch1%1 ;channel 1 if macro is 1 
	mov r0, #10000000B ; single ended, read channel 0
	ljmp sendit%1
MCPch1%1:
	mov r0, #10100000B ; single ended, read channel 1
sendit%1:
	lcall DO_SPI_G; send second byte
	mov a, r1 ; filter out garbage bits of result
	anl a, #00000011B ;keep only lower 2 bits
	
	mov r0, #0
	cjne r0, #%0, ktype_read%1
	mov voltage_return+1, a ; save result high
	lcall DO_SPI_G
	mov voltage_return , r1; save 2nd part of result low
	ljmp disable_mcp%1

ktype_read%1:
	mov voltage_return_ktype+1, a ; save result high
	lcall DO_SPI_G
	mov voltage_return_ktype , r1; save 2nd part of result low

disable_mcp%1:
	setb CE_ADC; disable slave
	
	pop acc ; retrive 3 registers used
	mov r1, a
	pop acc
	mov r0, a
	pop acc
	
ENDMAC

move2byte MAC
	mov %0, %1
	mov %0+1, %1+1
ENDMAC





