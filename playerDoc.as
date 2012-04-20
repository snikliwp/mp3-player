package  {
	
	import flash.display.MovieClip;
	
	import flash.filters.*
	
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundLoaderContext;
	import flash.media.SoundTransform;
	import flash.media.SoundMixer;

	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.IOErrorEvent;	// local filesystem errors and corrupted file handling
	import flash.events.HTTPStatusEvent;
	
	import flash.utils.Timer;
	import flash.utils.ByteArray;
	
	import flash.display.LoaderInfo;
	import flash.display.Graphics;
	import flash.display.Sprite;
	
	import flash.net.URLRequest;		// Go get the xml file
	import flash.net.URLLoader;			// Load the xml file
	
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import flash.geom.Rectangle;

	




	
	public class playerDoc extends MovieClip {
		
		public var songListXML:Array = new Array;	// this will be retrieved from an XML file
		public var path:String = './music/';
		public var currentTrack:Number = 0;
		public var position:Number = 0;
		public var numSong:Number = 0;
		public var isPlaying:Boolean = false;
		public var s:Sound = new Sound;
		public var sc:SoundChannel;
		public var context:SoundLoaderContext = new SoundLoaderContext(4000);
		public var timmy:Timer = new Timer(100, 0);
		public var vol:Number = 0.4;
		public var titleFormat:TextFormat = new TextFormat();
		public var glowR:GlowFilter = new GlowFilter;
		public var glowB:GlowFilter = new GlowFilter;
		public var playList_mc:MovieClip;								// new playlist
		public var listEntry_mc:MovieClip;								// new playlist
		public var playListXML:String = "playlist.xml";			// name of the xml file
		public var listXML:XML;									// array to store the xml data
		public var req:URLRequest = new URLRequest();				// Set up to get the xml data 
		public var xmlLoader:URLLoader = new URLLoader();			// Set up to get the images
		public var bytes:ByteArray = new ByteArray();
		public var leftBase:Number = 9;
		public var rightBase:Number = 21;
		public var startX:Number = 114;
		public var visualization:Sprite = new Sprite();
		public var st:SoundTransform;

		public static const CLICK:String = "click";




public function playerDoc() {
//			trace('in function playerDoc: ');
			// constructor code
			req = new URLRequest(playListXML);	
			xmlLoader = new URLLoader();										// Set up to get the images
			xmlLoader.addEventListener(Event.COMPLETE, getData);				// Event Listener for successful Completion
			xmlLoader.addEventListener(IOErrorEvent.IO_ERROR, xmlError);		// Event Listener for some Sort of IO Error
			xmlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, error404);	// Event Listener for a specific IO error - file not found
			xmlLoader.load(req);												// go get the XML file

			playlist_button.addEventListener(MouseEvent.ROLL_OVER, playList); 
			play_button.addEventListener(CLICK, playClick); 
			pause_button.addEventListener(CLICK, pauseClick); 
			stop_button.addEventListener(MouseEvent.CLICK, stopClick); 
			next_button.addEventListener(MouseEvent.CLICK, nextClick); 
			previous_button.addEventListener(MouseEvent.CLICK, prevClick); 

			volumeControl_mc.addEventListener(MouseEvent.CLICK, setNewVolume);
			volumeControl_mc.addEventListener(MouseEvent.MOUSE_DOWN, startVolumeTracking);
			volumeControl_mc.addEventListener(MouseEvent.MOUSE_UP, stopVolumeTracking);
			volumeControl_mc.volumeControlMask.scaleX = vol;

			timmy.addEventListener(TimerEvent.TIMER, updateInterface);
			seek_mc.load_fill_mc.scaleX = 0;
			seek_mc.play_fill_mc.scaleX = 0;
			seek_mc.handle_mc.x = 0;

			seek_mc.hit_mc.addEventListener(MouseEvent.CLICK, jumpTo);
			
			glowB.color = 0x0000ff;
			glowR.color = 0xff0000;
			stop_button.filters = [glowB];
			previous_button.filters = [glowB];
			next_button.filters = [glowB];
			pause_button.filters = [glowB];
			play_button.filters = [glowB];
			playlist_button.filters = [glowB];
			
			this.addChild(visualization);
			this.addEventListener(Event.ENTER_FRAME, createVisualization);
			
		}// end function playerDoc
		
		
		public function jumpTo(ev:MouseEvent):void{
			trace('in function jumpTo: ');
			//move to a new point on the song's timeline and start playing from there
				//pause the song
				pause_button.dispatchEvent( new MouseEvent("click") );		//this will have set the position variable that we need to overwrite
				
				var pct:Number = ev.localX / ev.currentTarget.width;
				//we will switch this to use the XML value instead of the s.length
				position = pct * s.length;
				
				//play from the new position
				play_button.dispatchEvent( new MouseEvent("click") );		
			}
		}// end function jumpTo
		
		public function playClick(ev:MouseEvent):void{
//			trace('in function playClick: ');
			//play the song
			if(!isPlaying){
				isPlaying = true;
				play_button.filters = [glowR];
				pause_button.filters = [glowB];
				nowPlaying_txt.text = listXML.song[currentTrack].title;
				playLength_txt.text = listXML.song[currentTrack].length;
				var req:URLRequest = new URLRequest(path + songListXML[currentTrack]);
				var trans:SoundTransform = new SoundTransform(vol, 0);
				s = new Sound(req, context);
				sc = s.play(position, 0, trans);
				
				s.addEventListener(ProgressEvent.PROGRESS, songLoading);
				sc.addEventListener(Event.SOUND_COMPLETE, songDone);
				
				timmy.start();
			}
		}// end function playClick
		
		public function songDone(ev:Event):void{
//			trace('in function songDone: ');
			//move to the next song
			next_button.dispatchEvent( new MouseEvent("click") );		
		}// end function songDone
		
		public function songLoading(ev:ProgressEvent):void{
//			trace('in function songLoading: ');
			//get the percentage and move the scaleX of the seek_mc.load_fill_mc a percentage of seek_mc.bg_mc.width
			var pct:Number = ev.bytesLoaded / ev.bytesTotal;
			if( pct < .98){
				//update the load fill bar
				seek_mc.load_fill_mc.scaleX = pct;
			}else{
				//if the pct is 99 or greater then remove the listener and set the scaleX to 100%
				s.removeEventListener(ProgressEvent.PROGRESS, songLoading);
				seek_mc.load_fill_mc.scaleX = 1;
			}
		}// end function songLoading
		
		public function updateInterface(ev:TimerEvent):void{
//			trace('in function updateInterface: ');
			if( isPlaying ){
				//update the seek bar
				//use the sc.position and (s.length OR the time from the XML) to calculate the percentage played
				var pct:Number = sc.position / s.length;
				//expand the scaleX of the play_fill_mc
				//move the x position of the handle_mc
				seek_mc.play_fill_mc.scaleX = pct;
				seek_mc.handle_mc.x = seek_mc.bg_mc.width * pct;
				
				//update the time
				//s.length is the length of the song in milliseconds -> we need to convert this to minutes and seconds
				var totalSeconds:Number = Math.floor( s.length / 1000) ;	//we want even numbers with no decimal place
				var currentSeconds:Number = Math.floor( pct * totalSeconds );		//my current number of seconds into the song
				
				var currentMinutes:Number = Math.floor( currentSeconds / 60);
				var remainderSeconds:Number = Math.floor( currentSeconds % 60 );
				var strMinutes:String = currentMinutes.toString();
				var strSeconds:String = remainderSeconds.toString();
				if( strSeconds.length == 1){
					strSeconds = "0" + strSeconds;		//add the leading zero to the seconds
				}
				time_mc.time_txt.text = strMinutes + ":" + strSeconds;
				
				//COUNTDOWN TIME
				var countDownSeconds:Number = totalSeconds - currentSeconds;
				currentMinutes = Math.floor( countDownSeconds / 60);
				remainderSeconds = Math.floor( countDownSeconds % 60 );
				strMinutes = currentMinutes.toString();
				strSeconds = remainderSeconds.toString();
				if( strSeconds.length == 1){
					strSeconds = "0" + strSeconds;		//add the leading zero to the seconds
				}
				countdown_txt.text = strMinutes + ":" + strSeconds;
				
				//update any animations that you have
				
			}
		}// end function updateInterface
		
		public function pauseClick(ev:MouseEvent):void{
//			trace('in function pauseClick: ');
			if(isPlaying){
				position = sc.position;
				stopSongCommon();
			} // end if
		}// end function pauseClick
		
		public function prevClick(ev:MouseEvent):void{
//			trace('in function prevClick: ');
			stop_button.dispatchEvent(new MouseEvent("click"));
			currentTrack--;
			if(currentTrack < 0){
				currentTrack = songListXML.length - 1;
			} // end if
			play_button.dispatchEvent(new MouseEvent("click"));
		}// end function prevClick
		
		public function nextClick(ev:MouseEvent):void{
//			trace('in function nextClick: ');
			stop_button.dispatchEvent(new MouseEvent("click"));
			currentTrack++;
			if(currentTrack >= songListXML.length){
				currentTrack = 0;
			} // end if
			play_button.dispatchEvent(new MouseEvent("click"));

		}// end function nextClick
		
		public function stopClick(ev:MouseEvent):void{
//			trace('in function stopClick: ');
			if(isPlaying){
				position = 0;
				stopSongCommon();
				//send the play fill bar and handle back to start
				seek_mc.play_fill_mc.scaleX = 0;
				seek_mc.handle_mc.x = 0;
			} // end if
		}// end function stopClick
		
		public function stopSongCommon():void{
//			trace('in function stopSongCommon: ');
			isPlaying = false;
//			play_button.visible = true;
			play_button.filters = [glowB];
			pause_button.filters = [glowR];
//			pause_button.visible = false;
			sc.stop();
			timmy.stop();
			sc.removeEventListener(Event.SOUND_COMPLETE, songDone);
		}// end function stopSongCommon
		
		public function setNewVolume(ev:MouseEvent):void{
//			trace('in function setNewVolume: ');
			//calculate the new volume percentage
			//create a new SoundTransform
			//pass it to the SoundChannel
			vol = ev.localX / volumeControl_mc.width;
			//ev.localX tells me the distance in the X direction from the volume_mc registration point
			var st:SoundTransform = new SoundTransform(vol, 0);
			sc.soundTransform = st;
			//set the mask to match the new volume
			volumeControl_mc.volumeControlMask.scaleX = vol;
		}// end function setNewVolume

		public function startVolumeTracking(ev:MouseEvent):void{
//			trace('in function startVolumeTracking: ');
			volumeControl_mc.addEventListener(MouseEvent.MOUSE_MOVE, setNewVolume);
		}// end function startVolumeTracking
		
		public function stopVolumeTracking(ev:MouseEvent):void{
//			trace('in function stopVolumeTracking: ');
			volumeControl_mc.removeEventListener(MouseEvent.MOUSE_MOVE, setNewVolume);
		}// end function stopVolumeTracking
		
		public function clearList(ev:MouseEvent):void{
//			trace('in function clearList: ');
			ev.target.removeEventListener(MouseEvent.ROLL_OUT, clearList);
			ev.target.parent.removeChild(ev.target);
		} // end function clearList
		
		public function getData(ev):void{
//			trace('in function getData: ');
			listXML = XML(ev.target.data);			// load the array with the data from the XML file
			numSong = listXML.song.length();		// number of level1 tags in the XML file
			
			for (var i:Number = 0; i <= numSong - 1; i++) {
				songListXML[i] = listXML.song[i].file;
			} // end for
			
		play_button.dispatchEvent( new MouseEvent("click") );		

		}// end function getData
		
		public function xmlError(ev):void{
//			trace('in function xmlError: ');
		}// end function xmlError
		
		public function error404(ev):void{
//			trace('in function error404: ');
		}// end function error404
		
		public function playList(ev:MouseEvent): void {
//			trace('in function playlist: ');
			// make the playlist visible expanding from the top
			var c:playListHolder = new playListHolder();
			c.x = 0;
			c.y = 75;
			this.addChild(c);
			
			c.addEventListener(MouseEvent.CLICK, changeSong);
			c.addEventListener(MouseEvent.ROLL_OUT, clearList);
			var ltf:TextFormat = new TextFormat(); // format for the list item
			var ypos:Number = -10;
			var d:listEntry;
			
			for (var i:Number = 0; i <= numSong - 1; i++) {
				d = new listEntry();
				d.listItemNum_txt.text = String(i + 1);
				d.listItemTitle_txt.text = listXML.song[i].title;
				d.listItemLength_txt.text =listXML.song[i].length;
				d.x = 5;
				d.y = ypos + 15;
				ypos = d.y;
				
				if (i == currentTrack) {
					ltf.color = 0x00ff00;
				} else { //end if
					ltf.color = 0x0000ff;
				} //end else
				
				d.height = 15;
				d.width = 295;
				ltf.size = 15;
				d.listItemNum_txt.setTextFormat(ltf);
				d.listItemTitle_txt.setTextFormat(ltf);
				d.listItemLength_txt.setTextFormat(ltf);
				d.listItemLength_txt.selectable = false;
				d.currentTrack = i; // add the track number of this selection to the clip so we can get at it later on
				d.buttonMode = true;
				d.useHandCursor = true;
				d.mouseChildren = false;
				c.addChild(d);
				c.height = 15 * int(numSong);
			} // end for loop
			
				// draw a nice border around the list holder
				c.graphics.clear();
				var r:Rectangle = c.getBounds(c);
				c.graphics.lineStyle(5.0, 0x000000, 1);
				c.graphics.moveTo(r.x, r.y);
				c.graphics.lineTo(r.x + r.width, r.y);
				c.graphics.lineTo(r.x + r.width, r.y + r.height);
				c.graphics.lineTo(r.x, r.y + r.height);
				c.graphics.lineTo(r.x, r.y);
				
		}// end function playlist
		
		public function changeSong(ev:MouseEvent): void {
//			trace('In function changeSong: ', ev.target);
			ev.target.removeEventListener(MouseEvent.CLICK, changeSong);
			currentTrack = ev.target.currentTrack -1;
			next_button.dispatchEvent(new MouseEvent("click"));
			clearList(ev);
		} // end function changeSong
		
		public function createVisualization(ev:Event):void{
//			trace('in function createVisualization: ');
			//24 times per second get the computeSpectrum and build a visualization
			SoundMixer.computeSpectrum(bytes);
			
			visualization.graphics.clear();
			visualization.graphics.lineStyle(1, 0x00FF00, 1);
			visualization.graphics.moveTo(startX, leftBase);
			var lChan:Number = new Number;
			var rChan:Number = new Number;
			for(var L:Number=0; L<120; L++){
				//left channel
				lChan = (bytes.readFloat() * 40 + leftBase);
				if (lChan < 4){lChan = 4;};
				if (lChan > 13){lChan = 13;};
				visualization.graphics.lineTo(startX+L, lChan);
			} // end for 
			
			visualization.graphics.lineStyle(1, 0xFF0000, 1);
			visualization.graphics.moveTo(startX, rightBase);
			
			for(var R:Number=256; R<376; R++){
				//right channel
				rChan = (bytes.readFloat() * 40 + rightBase);
				if (rChan < 16){rChan = 16;};
				if (rChan > 25){rChan = 25;};
				visualization.graphics.lineTo(startX+R-255, rChan);
			} // end for 
		} // end function createVisualization
		
		
		
	}// end class playerDoc
	
}// end package playerDoc
