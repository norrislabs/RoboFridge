{{ TestDS1620.spin }}

' ==============================================================================
'
'   File...... TestDS1620.spin
'   Purpose... Tes harness for DS1620 object
'   Author.... (C) 2010 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 05/13/2010
'   Updated...
'
' ==============================================================================

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{
  This is a description of the program.
}}


' ------------------------------------------------------------------------------
' Revision History
' ------------------------------------------------------------------------------
{{
  1019a - First version
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000


  ' Pins
  Pin_Lcd       = 16

  Pin_DQ        = 20  
  Pin_CLK       = 21
  Pin_Reset     = 22
  

VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------


DAT
        Title     byte "Test DS1620",0



OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  Temp          : "DS1620"
  Lcd           : "debug_lcd"

  
PUB Init | c,f
' ------------------------------------------------------------------------------
' Public Procedures
' ------------------------------------------------------------------------------

  ' Initialize the LCD
  Lcd.init(Pin_Lcd, 19200, 4)                          
  Lcd.cls
  Lcd.home
  Lcd.cursor(0)                                     
  Lcd.backLight(true)
  
  SetLcdPos(0,0)
  Lcd.str(@Title)

  ' Start DS1620
  Temp.Start(Pin_DQ, Pin_CLK, Pin_Reset)

  repeat
    c := Temp.GetTempC
    f := Temp.GetTempF

    SetLcdPos(2,0)
    Lcd.dec(f / 10)
    Lcd.putc(".")
    Lcd.dec(f - f / 10 * 10)
    Lcd.str(string(" F"))
    
    SetLcdPos(2,10)
    Lcd.dec(c / 10)
    Lcd.putc(".")
    Lcd.dec(c - c / 10 * 10)
    Lcd.str(string(" C"))
    
    Pause_ms(100)
    

' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
  