{{ DS1620.spin }}

' ==============================================================================
'
'   File...... DS1620.spin
'   Purpose... DS1620 Object
'   Author.... (C) 2010 Steven R. Norris -- See end of file for terms of use. 
'   E-mail.... steve@norrislabs.com
'   Started... 05/13/2010
'   Updated...
'
' ==============================================================================

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{
  Adapted from Beau Schwabe "SPI Spin DEMO" object.
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

  WrCfg   = $0C           '' write config register
  StartC  = $EE           '' start conversion
  RdTmp   = $AA           '' read temperature


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  long m_Pin_DQ
  long m_Pin_CLK
  long m_Pin_Reset

  long m_Celsius
  long m_Fahrenheit
  

OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  SPI           : "SPI_Spin"                              ''The Standalone SPI Spin engine


PUB Start(Pin_DQ, Pin_CLK, Pin_Reset)
' ------------------------------------------------------------------------------
' Public Procedures
' ------------------------------------------------------------------------------

  m_Pin_DQ := Pin_DQ
  m_Pin_CLK := Pin_CLK
  m_Pin_Reset := Pin_Reset
                                                                         
  SPI.start(15,1)           '' Initialize SPI Engine with Clock Delay of 15us and Clock State of 1

  HIGH(m_Pin_Reset)                                             '' alert the DS1620
  SPI.SHIFTOUT(m_Pin_DQ, m_Pin_CLK, SPI#LSBFIRST , 8, WrCfg)    '' Request Configuration Write
  SPI.SHIFTOUT(m_Pin_DQ, m_Pin_CLK, SPI#LSBFIRST , 8, %10)      '' configure for ; CPU / Free-run mode
  LOW(m_Pin_Reset)                                              '' release the DS1620
   
  Pause_ms(10)                                                  '' Pause for 10ms
   
  HIGH(m_Pin_Reset)                                             '' alert the DS1620
  SPI.SHIFTOUT(m_Pin_DQ, m_Pin_CLK, SPI#LSBFIRST , 8, StartC)   '' Request a Start Conversion   
  LOW(m_Pin_Reset)                                              '' release the DS1620


PUB GetTempC

  ReadTemp
  return m_Celsius


PUB GetTempF

  ReadTemp
  return m_Fahrenheit
  
    
PRI ReadTemp

  HIGH(m_Pin_Reset)                                             '' alert the DS1620
  SPI.SHIFTOUT(m_Pin_DQ, m_Pin_CLK, SPI#LSBFIRST , 8, RdTmp)    '' Request to read the temperature
  m_Celsius := SPI.SHIFTIN(m_Pin_DQ, m_Pin_CLK, SPI#LSBPRE, 9)  '' read the temperature
  LOW(m_Pin_Reset)                                              '' release the DS1620
   
  m_Celsius := m_Celsius << 23 ~> 23                    '' extend sign bit
  m_Celsius *= 5                                        '' convert to tenths  
   
  m_Fahrenheit := m_Celsius * 9 / 5 + 320               '' convert Celsius reading to Fahrenheit  
   
   
' ------------------------------------------------------------------------------
' Misc
' ------------------------------------------------------------------------------

PUB HIGH(Pin)
    dira[Pin]~~
    outa[Pin]~~
    
         
PUB LOW(Pin)
    dira[Pin]~~
    outa[Pin]~


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))


DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}  