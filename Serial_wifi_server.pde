import processing.net.*;
import java.io.FileWriter;
import java.io.IOException;

Server server; //サーバクラスの宣言
final int MAX_CLIENT = 2;
int Sensor_Data_Length = 13; //データの長さ

Server[] myServer = new Server[MAX_CLIENT];
String[] ServerIP = new String[MAX_CLIENT];

Client[] myClient = new Client[MAX_CLIENT];
String[] ClientIP = new String[MAX_CLIENT];

//String[] ClientID = {"1", "2", "B"};
String[] ClientID = {"A", "B"};
int ClientB = 1;

int State;

String[] Message = new String[MAX_CLIENT]; //送信メッセージ

FileWriter filewriter=null ;

void setup() { 
  size(800, 400);
  
  PFont font = createFont("BIZ UDゴシック", 16, true);
  textFont(font);

  myServer[0] = new Server(this, 5554);
  myServer[1] = new Server(this, 6554);

  for(int i = 0; i<MAX_CLIENT; i++) {
    ServerIP[i] = myServer[i].ip();
    ClientIP[i] = " ";
    Message[i] = "";
  }
  State = 0;
}

void stop() {
  for (int i = 0; i<MAX_CLIENT; i++) {
    myServer[i].stop();
  }
}

void draw() {
  background(#086C52);
  for (int i =0; i < MAX_CLIENT; i++) {
  text("サーバー    : " + ServerIP[i] + ", 状態 : " + State, 30, 20+i*100);//30, 20+~~は位置
  text("クライアント"   + ClientID[i] + ": " + ClientIP[i] , 30, 40+i*100);
  text(Message[i]                                          , 30, 60+i*100);
  }
}

//クライアントが接続したときに起動される
//conserverはサーバとポートの情報
//conclientは接続してきたクライアントの情報
void serverEvent(Server ConServer, Client ConClient) {
  //クライアントがどのポートから接続してきたかチェック
  for ( int i = 0; i<MAX_CLIENT; i++) {
    
    if ( ConServer == myServer[i]) {
      println(ConClient + " , " + myServer[i] + ", " + myClient);
      myClient[i] = ConClient;
      ClientIP[i] = ConClient.ip();
      Message[i] = "クライアント"+ ClientID[i] +"と接続";
    }
    delay(100);
    for (int j = 0; j < MAX_CLIENT; j++)  {
      byte sendData = (byte)j;
      myServer[j].write(sendData);
    }
    State = 1;
  }
  
}


//clientEvent
void clientEvent(Client RecvClient){
  //受信したデータ(受信バッファ内)のバイト数を取得
  int NumBytes = RecvClient.available( );
  int Number = 0;
  
  switch(State) {
    case 0:
      break;
    
    case 1:
      int k;
      
      //元のデータの2倍以上データを受け取ったなら
      if (NumBytes >= 2*Sensor_Data_Length) {
        byte [] myBuffer = RecvClient.readBytes();
        
        for (k=0; k<=NumBytes && myBuffer[k] != 's'; k++) { //順番を変えるとエラー
        }
        
        if (k+Sensor_Data_Length <= NumBytes) {
          //Number
           for ( int i = 0; i<MAX_CLIENT; i++) {
             if ( RecvClient == myClient[i]) {
               Number = i+1; 
               break;
             }
           }
           
          int Voltage = ( myBuffer[3+k+1] & 0xff ) << 24
                    | ( myBuffer[2+k+1] & 0xff ) << 16
                    | ( myBuffer[1+k+1] & 0xff ) << 8
                    | myBuffer[0+k+1] & 0xff;
                    
          int Percentage10 = ( myBuffer[7+k+1] & 0xff ) << 24
                    | ( myBuffer[6+k+1] & 0xff ) << 16
                    | ( myBuffer[5+k+1] & 0xff ) << 8
                    | myBuffer[4+k+1] & 0xff;
                    
          int PassTime = ( myBuffer[11+k+1] & 0xff ) << 24
                    | ( myBuffer[10+k+1] & 0xff ) << 16
                    | ( myBuffer[9+k+1] & 0xff ) << 8
                    | myBuffer[8+k+1] & 0xff;
                                        
          String str = String.format("Number:%02d, Voltage:%,5d [mV], 残量:%3d [％], 経過時間:%,9d[s]  (%4d/%2d/%2d/%2d:%2d:%02d)\n", 
                                      Number, Voltage, Percentage10/10, PassTime, year(), month(), day(), hour(), minute(), second());
                                      
          Message[Number-1] = String.format("Number:%02d, Voltage:%,5d [mV], 残量:%3d [％], 経過時間:%,9d[s]", Number, Voltage, Percentage10/10, PassTime); //<>//

          //クライアントBに送信 2回
          myServer[ClientB].write('s');
          myServer[ClientB].write(Number);     
          
          myServer[ClientB].write(Percentage10);
          myServer[ClientB].write(Percentage10 >> 8);
          myServer[ClientB].write(Percentage10 >> 16);
          myServer[ClientB].write(Percentage10 >> 24);   
          
          myServer[ClientB].write(PassTime);
          myServer[ClientB].write(PassTime >> 8);
          myServer[ClientB].write(PassTime >> 16);
          myServer[ClientB].write(PassTime >> 24); //<>//
          Message[ClientB] = String.format("以下を送信:\nNumber:%02d, 残量:%3d [％], 経過時間:%,9d[s]", Number, Percentage10/10, PassTime);
          
          try {
            String LogsPath = sketchPath("");
            File Savefile = new File(LogsPath + "/logs/number"+ Number + ".txt");
            filewriter = new FileWriter(Savefile, true);
            filewriter.write(str);
            filewriter.close();
            }
          catch(IOException e) {
            println(e);
          }  //<>//
        }
        
        RecvClient.clear( ); //受信バッファを空にする．
      }
        break; //case 1 終わり 
        
    default:
      break;
  }
}
