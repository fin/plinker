OscRecv recv;
// use port 6449 (or whatever)
9999 => recv.port;
// start listening (launch thread)
recv.listen();

// create an address in the receiver, store in new variable
recv.event( "/plinker/chat,f" ) @=> OscEvent @ oeChat;

SndBuf Chatter[5];
string fname[5];
0 => int glob_chat;

spork ~ chat_listener();

while(true){
    10::second => now;
}


   

fun void chat_listener(){
    "crowd_outside_1.wav" => fname[0];
    "crowd_outside_2.wav" => fname[1];
    "crowd_outside_3.wav" => fname[2];
    "crowd_outside_4.wav" => fname[3];
    <<<"init chatter">>>;
    for (0 => int k; k<4; k++)
    {
        fname[k] => Chatter[k].read;
        0.0 => Chatter[k].gain;1 => Chatter[k].loop;
        Chatter[k] => dac;
    }
    <<<"init chatter done">>>;
    
    spork ~ chat_player();
    
    oeChat => now;
    while( oeWeb.nextMsg() )
    { 
        oeChat.getFloat() => float factor;

        //Std.rand2f(0.0,4.0) => float factor;
        <<<"WEB: " + factor>>>;
        if(factor > 2.0){glob_chat + 1 => glob_chat;}
        if(factor < 0.5){glob_chat - 1 => glob_chat;}
        if(glob_chat < 0){ 0 => glob_chat;}
        if(glob_chat > 4){ 4 => glob_chat;}
        
        <<<glob_chat>>>;
        5::second => now;
    }
    
    
}

fun void chat_player(){
    while(true){
        if(glob_chat > 0){0.5 => Chatter[0].gain;}
        if(glob_chat > 1){0.5 => Chatter[1].gain;}
        if(glob_chat > 2){0.5 => Chatter[2].gain;}
        if(glob_chat > 3){0.5 => Chatter[3].gain;}
        1::minute/140 => now;    
    
        0.0 => Chatter[0].gain;
        0.0 => Chatter[1].gain;
        0.0 => Chatter[2].gain;
        0.0 => Chatter[3].gain;
    }
}