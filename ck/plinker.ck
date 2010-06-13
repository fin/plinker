//General Synchronisation of 
140 => float bpm;
1::minute/bpm * 4 => dur takt;
1::minute/bpm * 2 => dur halbe;
1::minute/bpm => dur viertel;
1::minute/bpm/2 => dur achtel;
1::minute/bpm/4 => dur sechzehntel;

OscRecv recv;
// use port 6449 (or whatever)
6449 => recv.port;
// start listening (launch thread)
recv.listen();

/*=== LISTENERS ===*/

//Listener
recv.event( "/plinker/inout,f" ) @=> OscEvent @ oeDrumFilter;
recv.event( "/plinker/count,f" ) @=> OscEvent @ oeDrumLayers;
recv.event( "/plinker/chat,f" ) @=> OscEvent @ oeChat;
recv.event( "/plinker/web,f" ) @=> OscEvent @ oeWeb;
recv.event( "/plinker/ssh, f" ) @=> OscEvent @ oeSSH;


/*=== END LISTENERS ===*/


/*=== INIT CHATTER ===*/

SndBuf Chatter[5];
string fname[5];
0 => int glob_chat;
0.8 => float chatgain;

/*=== END INIT CHATTER ===*/


/*=== INIT DRUMLOOP ===*/

0 => int glob_msg;
4 => int drumfilter; //Startindex fur drumfilter
1 => float last_count;
1 => float curr_count;

[50, 100, 500, 1000, 2000, 3000, 4000, 5000, 6000] @=> int drumfilter_cutoff[];
7 => int MAX_LAYERS;
8 => int MAX_CUTOFF;

SndBuf drums[MAX_LAYERS];
string filename[MAX_LAYERS];

"_sample_BD.wav" => filename[0]; //BD
"_sample_SD.wav" => filename[1]; //SD
"_sample_CH.wav" => filename[2]; //CH
"_sample_OH.wav" => filename[3]; //OH
"_sample_CP.wav" => filename[4]; //CP
"_sample_CB1.wav" => filename[5]; //CB
"_sample_CB2.wav" => filename[6]; //CB2

[1,0,0,0,1,0,0,1,1,0,0,0,1,0,0,0]  @=> int bd_row[];
[0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,1]  @=> int cp_row[];
[0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,1]  @=> int sd_row[];
[0,1,1,0,0,1,1,0,0,1,1,1,0,1,1,0]  @=> int ch_row[];
[0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1]  @=> int oh_row[];
[0,1,1,1,0,1,1,0,0,1,1,1,0,1,1,0]  @=> int cb_row[];
[1,1,0,0,1,1,0,0,1,1,0,0,1,1,1,1]  @=> int cb2_row[];

<<<"Loading drums...">>>;
// load the filename[] to drums[]
for (0 => int k; k<MAX_LAYERS; k++)
{
    filename[k] => drums[k].read;
}
<<<"...done">>>;

<<<"Connecting drums to dac...">>>;
//connect drums[] to dac and set gain

LPF filter[MAX_LAYERS];

for (0 => int j; j<MAX_LAYERS; j++)
{
    0.3 => drums[j].gain;
    //0.01 => filter[j].Q;
    drumfilter_cutoff[drumfilter] => filter[j].freq;
    drums[j] => filter[j] => dac;
}
<<<"...done">>>;

/*=== END INIT DRUMLOOP ===*/

/*=== INIT WEB ===*/

Rhodey voc=> JCRev r => Echo a => Echo b => Echo c => dac;
0.0 => float vocgain;


/*=== END INIT WEB ===*/



/*=== SPORKS ===*/

spork ~ play_drums();
spork ~ inout_listener();
spork ~ count_listener();
spork ~ chat_listener();
spork ~ web_listener();
spork ~listen_ssh_keyboard();

/*=== END SPORKS ===*/



//Runtime Loop
while (true)
{
    1::second => now;
}


/*=== CHATTER FUNCS ===*/

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
    while(true){
    oeChat => now;
    while( oeChat.nextMsg() )
    { 
        oeChat.getFloat() => float chatfactor;
        //Std.rand2f(0.0,4.0) => float factor;
        <<<"CHAT: " + chatfactor>>>;
        if(chatfactor >= 1.0){glob_chat + 1 => glob_chat;}
        if(chatfactor < 1.0){glob_chat - 1 => glob_chat;}
        if(glob_chat < 0){ 0 => glob_chat;}
        if(glob_chat > 4){ 4 => glob_chat;}
        if(glob_chat > 0){ 0.8 => chatgain;}
        
        
        <<<"GlobChat: " + glob_chat + "   Factor: " + chatfactor>>>;
        
    }
}
    
    
}

fun void chat_player(){
    0.8 => chatgain;
    while(true){
        if(glob_chat <= 4){
            chatgain => Chatter[0].gain;
            chatgain => Chatter[1].gain;
            chatgain => Chatter[2].gain;
            chatgain => Chatter[3].gain;
        }
        if(glob_chat <= 3){
            chatgain => Chatter[0].gain;
            chatgain => Chatter[1].gain;
            chatgain => Chatter[2].gain;
            0.0 => Chatter[3].gain;
            }
        if(glob_chat <= 2){
            chatgain => Chatter[0].gain;
            chatgain => Chatter[1].gain;
            0.0 => Chatter[2].gain;
            0.0 => Chatter[3].gain;
        }
        if(glob_chat <= 1){
            chatgain => Chatter[0].gain;
            0.0 => Chatter[1].gain;
            0.0 => Chatter[2].gain;
            0.0 => Chatter[3].gain;
        }
        //if(glob_chat == 0){
        //    0.0 => Chatter[0].gain;
        //    0.0 => Chatter[1].gain;
        //    0.0 => Chatter[2].gain;
        //    0.0 => Chatter[3].gain;
        //}
        
        
        1::minute/140 => now;    
        if(chatgain > 0.1){
            chatgain - 0.1 => chatgain;}
        //<<<"CHATGAIN: " + chatgain>>>;
        
//        0.0 => Chatter[0].gain;
//        0.0 => Chatter[1].gain;
//        0.0 => Chatter[2].gain;
//        0.0 => Chatter[3].gain;
    }
}

/*=== END CHATTER FUNCS ===*/














/*=== WEB FUNCS ===*/

fun void web_listener(){
    
    spork ~ web_player();
    
    while(true){
        oeWeb => now;
        while( oeWeb.nextMsg() )
        { 
            oeWeb.getFloat() => float factor;
            //<<<"WEB: " + factor>>>;
            //if(factor > maxfactor){
            //   factor => maxfactor;
            //    <<<maxfactor>>>;
            //    }
            
            if(factor == 1.000){
                vocgain * 0.3 => vocgain;
                //140 => bpm;
            }
            else{
                0.2 * factor + vocgain => vocgain;
                //140 + 10 * factor => bpm;
            }
            
            if(vocgain > 1){
                1.0 => vocgain;
            }
            if(bpm > 280){
                280 => bpm;
            }                
            //<<< "WEBFActor: " + factor + "   ; New Gain: " + vocgain + "   BPM: " + bpm >>>;
            
            vocgain => voc.gain;
        }
        
    }
}

fun void web_player(){
    
    [ 0, 4, 2, 7, 9, 11, 9, 7 ] @=> int scale[];
    
    220.0 => voc.freq;
    0.0 => voc.gain;
    .8 => r.gain;
    .2 => r.mix;
    0::ms => a.max => b.max => c.max;
    750::ms => a.delay => b.delay => c.delay;
    .50 => a.mix => b.mix => c.mix;
    
    takt - (now % takt) => now;
    
    while(true){
        for(0 => int i; i < scale.cap(); i++){
            scale[i] => int freq;
            Std.mtof( ( 33 + freq ) ) => voc.freq;
            0.8 => voc.noteOn;
            achtel => now;
            vocgain * 0.8 => voc.gain;
            vocgain * 0.8 => vocgain;
        }
        
    }
}

/*=== END WEB FUNCS ===*/







/*===  SSH FUNCS ===*/

fun void listen_ssh_keyboard()
{
    // spork the player.
    //spork ~play_ssh_clarinet();
    
    float ssh_packets;
    float gain;
    
    while (true)
    {
        oeSSH => now;
        
        // listen to osc
        while (oeSSH.nextMsg() )
        {
            oeSSH.getFloat() => ssh_packets;
            if (ssh_packets > 1.0)
                0.5 + ( 0.1 * ssh_packets $ int) => gain;
            else
                0.3 => gain;
            
            if (gain > 0.8)
                0.8 => gain;
            
            spork ~play_ssh_keyboard(gain);
            
            <<< "ssh_value:" + ssh_packets >>>;
            <<< "gain:" + gain >>>;
            
        }
    }
    
}

fun void play_ssh_keyboard(float gainor)
{
    SndBuf keyboard_buffer;
    // keyboard buffer
    "keyboard2.wav" => keyboard_buffer.read;
    gainor => keyboard_buffer.gain;
    0 => keyboard_buffer.loop;
    keyboard_buffer => dac;
    
    5::second => now;
}


/*=== END SSH FUNCS ===*/







/*=== DRUMLOOP FUNCS ===*/
fun void play_drums()
{
    takt - (now % takt) => now; //synch am taktbeginn
    //0 => int drum_index;
    0 => int curr_pos;
    <<<"Play the drums">>>;
    while(true)
    {
        //update_drum_row();
        //<<<"drum_index: ", drum_index>>>;
        //drums[drum_index].play;
        
        if (bd_row[curr_pos])
        {
            0 => drums[0].pos; 
            //<<<"BD">>>;
        }
        if (glob_msg > 0)
        {
            if (cp_row[curr_pos])
            {
                0 => drums[4].pos; 
                //<<<"CP">>>;
            }
            if (glob_msg > 1)
            {
                if (sd_row[curr_pos])
                {
                    0 => drums[1].pos; 
                    //<<<"SD">>>;
                }
                if (glob_msg > 2)
                {
                    if (oh_row[curr_pos])
                    {
                        0 => drums[3].pos; 
                        //<<<"OH">>>;
                    }
                    if (glob_msg > 3)
                    {
                        if (ch_row[curr_pos])
                        {
                            0 => drums[2].pos; 
                            //<<<"CH">>>;
                        }
                        if (glob_msg > 4)
                        {
                            if (cb_row[curr_pos])
                            {
                                0 => drums[5].pos; 
                                //<<<"CB">>>;
                            }
                            if (glob_msg > 5)
                            {
                                if (cb2_row[curr_pos])
                                {
                                    0 => drums[6].pos; 
                                    //<<<"CB2">>>;
                                }
                            }
                        }
                    }
                }
            }
        }
        (curr_pos +1)%16 => curr_pos;
        //<<<curr_pos>>>;
        1::sechzehntel => now;
    }
}

fun void count_listener()
{
    while(true)
    {
        //<<< "trying recv count" >>>;
        oeDrumLayers => now;
        //<<< "recv count" >>>;
        while( oeDrumLayers.nextMsg() )
        { 
            1 => float factor;
            //<<< "FOO" >>>;
            oeDrumLayers.getFloat() => float osc_count;
            //<<< "Float osc_count: " + osc_count >>>;
            curr_count => last_count;
            osc_count => curr_count;
            if (last_count != 0)
            {
                curr_count / last_count => factor;
            }
            else 
            {
                curr_count => factor;
            }
            //<<< "Float factor: " + factor >>>;
            if (factor > 1 && glob_msg < MAX_LAYERS)
            {
                glob_msg++;
            } 
            else if (factor < 0.5 && glob_msg > 0)
            {
                glob_msg--;
            }
        }
    }
}

fun void inout_listener()
{
    
    while(true)
    {
        //<<< "trying recv inout" >>>;
        oeDrumFilter => now;
        //<<< "recv inout" >>>;
        while( oeDrumFilter.nextMsg() )
        { 
            //<<< "FOO" >>>;
            oeDrumFilter.getFloat() => float factor;
            //<<< "DRUMFILTER: " + factor >>>;
            if (factor > 2 && drumfilter < MAX_CUTOFF)
            {
                drumfilter++;
            } 
            else if (factor < 0.5 && drumfilter > 0)
            {
                drumfilter--;
            }
            for (0 => int l; l<MAX_LAYERS; l++)
            {
                drumfilter_cutoff[drumfilter] => filter[l].freq;
            }
        }
    }
}



