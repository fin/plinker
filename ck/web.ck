OscRecv recv;
// use port 6449 (or whatever)
6449 => recv.port;
// start listening (launch thread)
recv.listen();

140 => float bpm;
1::minute/bpm * 4 => dur takt;
1::minute/bpm * 2 => dur halbe;
1::minute/bpm => dur viertel;
1::minute/bpm/2 => dur achtel;
1::minute/bpm/4 => dur sechzehntel;

viertel => dur web_duration;


// create an address in the receiver, store in new variable
<<<<<<< HEAD
recv.event( "/plinker/web, f" ) @=> OscEvent @ oeWeb;
=======
recv.event( "/plinker/web,f" ) @=> OscEvent @ oeWeb;
>>>>>>> e4a5f290b70bcc66b71b40061950082529b4c542

Rhodey voc=> JCRev r => Echo a => Echo b => Echo c => dac;
    
spork ~ web_listener();    

while(true){
    10::second => now;
}

fun void web_listener(){
   
   //debug
   [ 0.5, 2.2, 0.7, 1.0, 1.0, 0.3, 1.3, 2 ] @=> float changes[]; 
    
   spork ~ web_player();
   0.8 => float vocgain;
   
   
   1 => int i;
   while(true){
<<<<<<< HEAD
   //     oeWeb => now;
        
   //     while( oeWeb.nextMsg() )
   //     { 
   
   
   changes[i] => float outFactor;
            
            changes[i] * web_duration => web_duration;
            <<<web_duration>>>;
            i + 1 => i;
            if(i > 28){1 => i; viertel => web_duration;}
            outFactor * vocgain => voc.gain;
            
            <<< "Float: " + outFactor>>>;
            web_duration => now;
   //     }
=======
       <<< "trying recv" >>>;
        oeWeb => now;
        <<< "recv" >>>;
        while( oeWeb.nextMsg() )
        { 
            <<< "FOO" >>>;
            oeWeb.getFloat() => float factor;
            <<< "Float: " + factor >>>;
            
        }
>>>>>>> e4a5f290b70bcc66b71b40061950082529b4c542
        
        //<<< web_duration >>>;
    }
}

fun void web_player(){

    [ 0, 4, 2, 7, 9, 11, 9, 7 ] @=> int scale[];

    220.0 => voc.freq;
    0.8 => voc.gain;
    .8 => r.gain;
    .2 => r.mix;
    0::ms => a.max => b.max => c.max;
    750::ms => a.delay => b.delay => c.delay;
    .50 => a.mix => b.mix => c.mix;

    while(true){
        for(0 => int i; i < scale.cap(); i++){
            scale[i] => int freq;
            Std.mtof( ( 33 + freq ) ) => voc.freq;
            0.8 => voc.noteOn;
            web_duration => now;
        }
        
    }
}
