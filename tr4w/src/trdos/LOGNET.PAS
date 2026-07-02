{
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }
unit LogNet;

{$IMPORTEDDATA OFF}

{ Has all of the lower level network interface routines in it.  Sits above
  LogK1EA which has the serial port support stuff in it }

interface

uses
  {Crt,}Tree, {SlowTree,}

  LogK1EA;

var
  //   ActiveMultiPort                 : PortType;

     //  K1EANetworkEnable                     : boolean = False; { Set to TRUE to deal with CT network }

  //   MultiPortBaudRate               : integer = 4800;

  NetDebug                              : boolean;
  NetDebugBinaryOutput                  : file;
  NetDebugBinaryInput                   : file;

procedure SendMultiMessage(Message: string);
procedure SetUpMultiPort;

implementation

uses uNet,
  MainUnit,
  LogWind;

procedure SetUpMultiPort;

begin
  //  if CPUKeyer.SlowInterrupts then
  //    CPUKeyer.SetUpSerialPort(ActiveMultiPort, MultiPortBaudRate, 8, NoParity, 2, 0)
  //  else
  //  CPUKeyer.SetUpSerialPort(ActiveMultiPort, MultiPortBaudRate, 8, NoParity, 2, 1);
end;



procedure SendMultiMessage(Message: string);

{ Works for both N6TR and K1EA Network modes }

var
  CharPointer                           : integer;
  wassend                               : integer;
  NET_Buffer                            : array[1..90] of Char;
begin
  if length(Message) > 0 then
  begin
      {
      if K1EANetworkEnable then
      begin

                 // We add the checksum and new line unless we already find
                 //  the new line there

        if message[length(message)] <> LineFeed then
        begin
          AddK1EACheckSumToString(message);
          message := message + LineFeed;
        end;
      end
      else
              //wli            Message := SlipMessage(Message);
        message := message;
       }
           { If we don't have enough room for the message, we will have to
             wait until we do as we have no other choice.  }

    if NetDebug then
    begin
          //{WLI}if CPUKeyer.SerialPortOutputBuffer[ActiveMultiPort].FreeSpace < length(Message) then
          //{WLI}                SendMorse ('PBF PBF');

          //{WLI}            SaveAndSetActiveWindow (BandMapWindow);
          //{WLI}            GoToXY (1, 22);
          //{WLI}            ClrEol;
    end;

      //{WLI}         while not CPUKeyer.SerialPortOutputBuffer[ActiveMultiPort].FreeSpace >= length(Message) do ;

    for CharPointer := 1 to length(Message) do
    begin
          //               CPUKeyer.SerialPortOutputBuffer[ActiveMultiPort].AddEntry(Ord(Message[CharPointer]));
      NET_Buffer[CharPointer] := Message[CharPointer];

      if NetDebug then
      begin
        BlockWrite(NetDebugBinaryOutput, Message[CharPointer], 1);

        if (Message[CharPointer] >= ' ') and
          (Message[CharPointer] <= 'z') then
          Write(Message[CharPointer]);
      end;
    end;
    if NetSocket = 0 then Exit;
    wassend := SendToNet(NET_Buffer, length(Message));
 //  if wassend + 1 <> CharPointer then         // 4.79.4 charpointer not used
        //      showmessage('Can`t sent' + #13 + message + #13 + 'Check connection');
                 //{WLI}         if NetDebug then  RestorePreviousWindow;
  end;
  
end;

begin
  //   ActiveMultiPort := NoPort;
end.
