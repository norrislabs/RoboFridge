{{ Fridge.spin }}

' ==============================================================================
'
'   File...... Fridge.spin
'   Purpose... RoboFridge
'   Author.... (C) 2010-2011 Steven R. Norris -- All Rights Reserved
'   E-mail.... steve@norrislabs.com
'   Started... 04/28/2010
'   Updated... 03/29/2011
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
  1021a - First version
  1113a - Updated to new link protocol
}}


CON
' ------------------------------------------------------------------------------
' Constants
' ------------------------------------------------------------------------------

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' IDs
  NetID         = "R"           ' Robot Network
  DevID         = "6"           ' RoboFridge ID

  ' Pins
  Pin_XBRx      = 0  
  Pin_XBTx      = 1

  Pin_GateA     = 3
  Pin_GateB     = 4

  Pin_Speaker   = 5
  
  Pin_Door      = 6
  Pin_DoorLimit = 7

  Pin_Reset     = 8
  Pin_CLK       = 9
  Pin_DQ        = 10

  Pin_Beacon    = 11  

  Pin_Led       = 16
  Pin_Lcd       = 21

  Pin_BtnGo     = 22
  Pin_BtnSelect = 23
  
  ' XBee
  XB_Baud       = 115200

  ' Door
  DoorStop      = 1480
  
  ' Gate positions
  GateUp        = 1500
  GateDown      = 600

  ' Menu selected operations
  MuOp_Idle          = 0
  MuOp_Dispense      = 1
  MuOp_OpenDoor      = 2
  MuOp_CloseDoor     = 3
  MuOp_Load6Cans     = 4

  ' RF selected operations
  RfOp_Idle          = 0
  RFOp_OpenDoor      = 1
  RFOp_CloseDoor     = 2
  RFOp_Dispense      = 3
  
  ' Last operation status codes
  ST_Unknown         = 0
  ST_OK              = 1
  ST_InProgress      = 2
  ST_Error           = 3
  
  ' Current door status codes
  DS_Unknown         = 0
  DS_Closed          = 1
  DS_Opened          = 2


VAR
' ------------------------------------------------------------------------------
' Variables
' ------------------------------------------------------------------------------

  ' RF command buffer
  byte m_Buffer[32]

  ' Current Task
  long m_Task
  long m_MenuItem

  long m_BlinkCog
  long m_BlinkStack[40]

  ' Status
  long m_Cans
  long m_DoorStatus
  long m_LastOp
  long m_LastOpStatus
  
  
DAT
        Title     byte "RoboFridge",0

        ' Task Menu (Name string, 0, function)
        Tasks     byte "Dispense?     ",0,MuOp_Dispense
                  byte "Load-6?       ",0,MuOp_Load6Cans
                  byte "Open Door?    ",0,MuOp_OpenDoor
                  byte "Close Door?   ",0,MuOp_CloseDoor


OBJ
' ------------------------------------------------------------------------------
' Objects
' ------------------------------------------------------------------------------

  Servo         : "Servo32v7"
  XB            : "XBee_Object"
  TempSensor    : "DS1620"
  Lcd           : "debug_lcd"
  Speaker       : "Speaker"
  

PUB Main | btn, ptrTask, dt
' ------------------------------------------------------------------------------
' Public Procedures
' ------------------------------------------------------------------------------

  ' LED on during initialize
  LedOn(true)
  
  ' Initialize the LCD
  Lcd.init(Pin_Lcd, 19200, 2)                          
  Lcd.cls
  Lcd.home
  Lcd.cursor(0)                                     
  Lcd.backLight(true)
  
  SetLcdPos(0,0)
  Lcd.str(@Title)

  ' Initialize speaker (uses 1 cog when producing sound)
  Speaker.Init(Pin_Speaker)

  ' Initialize Servo and servos
  Servo.Start
  Servo.Set(Pin_GateA, GateUp)
  Servo.Set(Pin_GateB, GateUp)

  ' Initialize door actuator
  DisplayMsg(string("Wait Door Pwr..."))
  InitDoor
  
  ' Init XBee
  DisplayMsg(string("Init Comm..."))
  XB.start(Pin_XBRx, Pin_XBTx, 0, XB_Baud)     
  XB.AT_Init
'  XB.AT_ConfigVal(string("ATMY"), MY_Addr)

  ' Start DS1620 temperature
  TempSensor.Start(Pin_DQ, Pin_CLK, Pin_Reset)

  ' Initial can count
  m_Cans := 6

  ' Initialization done
  LedOn(false)
  BeaconOn(true)
  Speaker.BeepDec(2)

  ' Start Alive blink
  m_BlinkCog := -1
  BlinkLed(0)

  ' Init menu 
  m_MenuItem := -1
  ShowMenuItem(m_MenuItem)
  
  ' Main Menu loop
  dt := 0
  repeat
    ProcessRF
    
    btn := TestButton
    if btn == Pin_BtnGo
      ptrTask := @Tasks + (m_MenuItem * 16)
      m_Task := byte[ptrTask][15]

    if btn == Pin_BtnGo
      ExecuteTask
      ShowMenuItem(m_MenuItem)
      
    elseif btn == Pin_btnSelect
      ' Select next possible task
      m_MenuItem++
      if m_MenuItem == 4
        m_MenuItem := 0
      ShowMenuItem(m_MenuItem)

    ' Update fridge temperature
    if dt == 0
      DisplayTemp
      dt := 5000                ' About a 1/2 second refresh rate
    dt--
    
' ------------------------------------------------------------------------------
' Process RF Commands
' ------------------------------------------------------------------------------
PRI ProcessRF

  ' Check for and process remote commands 
   if GetHeader
     if GetCmd
     ' Open Door
      if(m_Buffer[0] == "F" and m_Buffer[1] == "1")
        BlinkLed(200)
        SendStatus(RfOp_OpenDoor, ST_InProgress)
        OpenDoor
        BlinkLed(0)
        SendStatus(RfOp_OpenDoor, ST_OK)
        
     ' Close Door
      if(m_Buffer[0] == "F" and m_Buffer[1] == "2")
        BlinkLed(200)
        SendStatus(RfOp_CloseDoor, ST_InProgress)
        CloseDoor
        BlinkLed(0)
        SendStatus(RfOp_CloseDoor, ST_OK)

     ' Dispense 1 Can, no door
      if(m_Buffer[0] == "F" and m_Buffer[1] == "3")
        if ina[Pin_DoorLimit] == 0 and m_Cans > 0
          SendStatus(RfOp_Dispense, ST_InProgress)
          Dispense(false)
          SendStatus(RfOp_Dispense, ST_OK)
        else
          SendStatus(RfOp_Dispense, ST_Error)
        
     ' Query Status
      if(m_Buffer[0] == "T" and m_Buffer[1] == "1")
        SendStatus(m_LastOp, m_LastOpStatus)

     ' Query Status Readable
      if(m_Buffer[0] == "T" and m_Buffer[1] == "2")
        SendStatusAscii(m_LastOp, m_LastOpStatus)

      ShowMenuItem(m_MenuItem)
    

PRI GetHeader : status | data

  status := false
  data := XB.rxcheck
  if data == ">"
    data := XB.rxtime(5000)
    if data == NetID
      data := XB.rxtime(5000)
      if data == DevID
        status := true

        
PRI GetCmd : status | data,i

  i := 0
  data := 0
  repeat while data <> -1
    data := XB.rxtime(5000)

    if data == 13
      m_Buffer[i] := 0
      status := true
      return

    m_Buffer[i] := data

    i++
    m_Buffer[i] := 0
    if i == 31
      quit

  status := false  


PRI SendStatus(task, status)

  XB.tx("<")
  XB.tx(NetID)
  XB.tx(DevID)
  XB.tx(task)
  XB.tx(status)
  XB.tx(m_DoorStatus)
  XB.tx(m_Cans)
  XB.tx(TempSensor.GetTempF / 10)
  XB.tx(13)

  m_LastOp := task
  m_LastOpStatus := status

  
PRI SendStatusAscii(task, status)

  XB.tx("<")
  XB.tx(NetID)
  XB.tx(DevID)
  XB.dec(task)
  XB.tx(",")
  XB.dec(status)
  XB.tx(",")
  XB.dec(m_DoorStatus)
  XB.tx(",")
  XB.dec(m_Cans)
  XB.tx(",")
  XB.dec(TempSensor.GetTempF / 10)
  XB.tx(13)
  
  m_LastOp := task
  m_LastOpStatus := status

  
' ------------------------------------------------------------------------------
' Process Menu Commands
' ------------------------------------------------------------------------------
PRI ExecuteTask
    
  case m_Task
    MuOp_Dispense:
      Dispense(true)
    
    MuOp_Load6Cans:
      LoadDispenser(6)       

    MuOp_OpenDoor:
      BlinkLed(200)
      OpenDoor
      BlinkLed(0)
    
    MuOp_CloseDoor:
      BlinkLed(200)
      CloseDoor       
      BlinkLed(0)

  m_Task := MuOp_Idle


PRI ShowMenuItem(item)

  Lcd.clrln(1)
  SetLcdPos(1, 0)

  if(item <> -1)
    Lcd.str(@Tasks + (item * 16))
  else
    DisplayMsg(string("Select?"))

  DisplayCans


PRI TestButton : btn

  if ina[Pin_BtnSelect] == 0
    Pause_ms(30)
    if ina[Pin_BtnSelect] == 0
      repeat while ina[Pin_BtnSelect] == 0
      return Pin_BtnSelect
      
  if ina[Pin_BtnGo] == 0
    Pause_ms(30)
    if ina[Pin_BtnGo] == 0
      repeat while ina[Pin_BtnGo] == 0
      return Pin_BtnGo

  return -1
  

' ------------------------------------------------------------------------------
' Door Functions
' ------------------------------------------------------------------------------

PRI InitDoor

  ' Wait for HB-25 to startup
  repeat until ina[Pin_Door] == 1
  outa[Pin_Door]~
  dira[Pin_Door]~~
  Pause_ms(5)
  
  Servo.Set(Pin_Door, DoorStop)

  ' Limit switch input
  dira[Pin_DoorLimit]~

  if ina[Pin_DoorLimit] == 0
    m_DoorStatus := DS_Opened
  else
    m_DoorStatus := DS_Closed
      

PRI OpenDoor | w

  if ina[Pin_DoorLimit] == 1
    
    BeaconOn(false)

    repeat w from 1500 to 1000 step 50
      Servo.Set(Pin_Door, w)
      Pause_ms(100)

    repeat
      repeat until ina[Pin_DoorLimit] == 0
        
      Pause_ms(10)
      if ina[Pin_DoorLimit] == 0
        quit
      
    Servo.Set(Pin_Door, DoorStop)
    m_DoorStatus := DS_Opened
    
    
PRI CloseDoor | w

  repeat w from 1500 to 2000 step 50
    Servo.Set(Pin_Door, w)
    Pause_ms(100)

  Pause_ms(19000)
  
  Servo.Set(Pin_Door, DoorStop)
  BeaconOn(true)
  m_DoorStatus := DS_Closed
  
    
' ------------------------------------------------------------------------------
' Dispenser
' ------------------------------------------------------------------------------

PRI LoadDispenser(Cans)

  BlinkLed(200)
  OpenDoor
  
  Servo.Set(Pin_GateA, GateUp)
  Servo.Set(Pin_GateB, GateDown)
     
  ' Wait for loading
  DisplayMsg(string("Load Cans"))
  repeat while ina[Pin_BtnSelect] == 1 and ina[Pin_BtnGo] == 1 

  m_Cans := m_Cans + Cans <# 6
  Lcd.clrln(1)
  DisplayCans
     
  Servo.Set(Pin_GateA, GateUp)
  Servo.Set(Pin_GateB, GateUp)

  CloseDoor
  BlinkLed(0)
       

PRI Dispense(Door)

  DisplayMsg(string("Dispensing..."))
  BlinkLed(200)

  if Door
    OpenDoor    

  Speaker.BeepDec(3)
  Pause_ms(1000)
  ToggleGateA

  if Door
    CloseDoor
  else
    Pause_ms(1000)

  if(m_Cans > 1)
    ToggleGateB

  m_Cans := m_Cans - 1 #> 0
     
  Lcd.clrln(1)
  DisplayCans
  BlinkLed(0)
    

PRI ToggleGateA

  if ina[Pin_DoorLimit] == 0
    Servo.Set(Pin_GateA, GateDown)
    Pause_ms(3000)
    Servo.Set(Pin_GateA, GateUp)
    Pause_ms(1000)


PRI ToggleGateB

  Servo.Set(Pin_GateB, GateDown)
  Pause_ms(3000)
  Servo.Set(Pin_GateB, GateUp)
  Pause_ms(1000)
    

' ------------------------------------------------------------------------------
' Beacon
' ------------------------------------------------------------------------------

PRI BeaconOn(yesno)

  dira[Pin_Beacon]~~
  if yesno
    outa[Pin_Beacon]~~
  else
    outa[Pin_Beacon]~


' ------------------------------------------------------------------------------
' LED
' ------------------------------------------------------------------------------

PRI BlinkLed(delay)

  BlinkLed2(delay, delay)

  
PRI BlinkLed2(delayOn, delayOff)

  if delayOn > 0
    if m_BlinkCog <> -1
      cogstop(m_BlinkCog)
    m_BlinkCog := cognew(Blinker(delayOn, delayOff), @m_BlinkStack)
  else
    if m_BlinkCog <> -1
      cogstop(m_BlinkCog)
    m_BlinkCog := cognew(Blinker(100, 10000), @m_BlinkStack)
      

PRI Blinker(delayOn, delayOff)

  repeat
    if m_Cans == 0
      Speaker.BeepDec(1)

    LedOn(true)
    Pause_ms(delayOn)
    LedOn(false)
    Pause_ms(delayOff)
    
      
PRI LedOn(yesno)

  dira[Pin_Led]~~
  if yesno
    outa[Pin_Led]~~
  else
    outa[Pin_Led]~


' ------------------------------------------------------------------------------
' LCD
' ------------------------------------------------------------------------------

PRI DisplayCans

  SetLcdPos(1, 15)
  Lcd.dec(m_Cans)
  

PRI DisplayTemp | f

  f := TempSensor.GetTempF
  
  SetLcdPos(0, 13)
  Lcd.dec(f / 10)
  Lcd.str(string("F"))
  
   
PRI DisplayMsg(msg)

  Lcd.clrln(1)
  SetLcdPos(1, 0)
  Lcd.str(msg)
    

PRI SetLcdPos(row, col)
  Lcd.gotoxy(col, row)


PRI Pause_ms(msDelay)
  waitcnt(cnt + ((clkfreq / 1000) * msDelay))
  