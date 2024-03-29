{{ Speaker.spin }}

' ==============================================================================
'
'   File...... Speaker.spin
'   Purpose... Piezo speaker support object
'   Author.... (C) 2006 Steven R. Norris -- All Rights Reserved
'   E-mail.... norris56@comcast.net
'   Started... 04/08/2007
'   Updated... 
'
' ==============================================================================

' ------------------------------------------------------------------------------
' Program Description
' ------------------------------------------------------------------------------
{{


}}


' ------------------------------------------------------------------------------
' Revision History
' ------------------------------------------------------------------------------
{{
  0714a - This is the first version
}}


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  byte m_PinSpkr
  byte m_Init
  

OBJ

  sw  : "SquareWave"                    ' Import square wave cog object


PUB Init(pin)
{{
  Initialize the Speaker object. Pass the pin number
  that is connected to the Piezo speaker.
}}

  m_PinSpkr := pin
  m_Init := true
  

PUB Beep(freq, dur)
{{
  Sound a beep at the specified frequency and duration
}}

  if m_Init
    BeepInt(m_PinSpkr,freq,dur)


    
PUB BeepDec(value) | i
{{
  Beep out a decimal number
}}

  if m_Init
    if value < 0                                          ' Send - sign if < 0               
      -value                                                                                    
                                                                                                
    i := 1_000_000_000                                                                          
                                                                                                
    repeat 10                                             ' test each 10's place             
      if value => i                                       ' send character based on ASCII 0  
        Beeps(value / i)                                  ' Take modulus of i                
        value //= i                                                                             
        result~~                                                                                
      i /= 10                                                                                           
     

PRI Beeps(count)

  repeat count
    BeepInt(m_PinSpkr, 1000, 200)
    Pause_ms(300)
    
  Pause_ms(500)
  

PRI BeepInt(pin, freq, dur) 

  sw.start(@pin)
  repeat until dur == 0
  sw.stop


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))    