  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring


;;;;;;;;;;;;;;;


  .bank 0
  .org $C000
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x    ;move all sprites off screen
  INX
  BNE clrmem

vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2



LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006    ; write the high byte of $3F00 address
  LDA #$00
  STA $2006    ; write the low byte of $3F00 address
  LDX #$00
LoadPalettesLoop:
  LDA palette, x        ;load palette byte
  STA $2007             ;write to PPU
  INX                   ;set index to next byte
  CPX #$20
  BNE LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done



LoadSprites:
  LDX #$00
 LoadSpritesLoop:
  LDA sprites, x
  STA $0200, x
  INX
  CPX #$18
  BNE LoadSpritesLoop


  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop



NMI:
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer


LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016


ReadA:
  LDA $4016


ReadB:
  LDA $4016


ReadSelect:
  LDA $4016


ReadStart:
  LDA $4016


ReadUp:
  LDA $4016


ReadDown:
  LDA $4016


ReadLeft:
  LDA $4016         ; player 1 - Left
  AND #%00000001    ; only look at bit 0 for Pressed or Not
  BEQ ReadLeftDone  ; branch to Done if Not Press

                    ; If It Is Pressed
  LDA $0203         ; load sprite X Position
  SEC               ; make sure Carry flag is clear so we pacman through the other side
  SBC #$01          ; subtract 1 from X position, with carry for pacmanning
  STA $0203         ; write the new X Position over the old one
ReadLeftDone:       ; button is no longer being pressed at this label


ReadRight:
  LDA $4016
  AND #%00000001
  BEQ ReadRightDone

  LDA $0203
  CLC
  ADC #$01
  STA $0203
ReadRightDone:


  RTI        ; return from interrupt

;;;;;;;;;;;;;;



  .bank 1
  .org $E000
palette:
  .db $00,$31,$32,$33,$00,$35,$36,$37,$00,$39,$3A,$3B,$00,$3D,$3E,$0F
  .db $00,$0F,$08,$36,$00,$02,$38,$3C,$00,$1C,$15,$14,$00,$02,$38,$3C

sprites:
  ; Pip Starting Sprite
     ;vert tile pal horiz
  .db $80, $03, $00, $80
  .db $80, $04, $00, $88
  .db $80, $05, $00, $90
  .db $88, $13, $00, $80
  .db $88, $14, $00, $88
  .db $88, $15, $00, $90





  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial


;;;;;;;;;;;;;;


  .bank 2
  .org $0000
  .incbin "pip_chr.bin"