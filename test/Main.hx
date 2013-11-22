package ;

import cad.Lock;
import cad.Thread;

class Main {

	public static function main ():Void {
		trace("Starting");
		var t = Thread.create(test);
		while (true) {
			#if cad
			trace(Thread.current().name + ": " + Thread.current().state);
			trace(t.name + ": " + t.state);
			#end
			Sys.sleep(1);
		}
	}
	
	static function test ():Void {
		var l = new Lock();
		#if cad
		Thread.current().name = "test-thread";
		#end
		trace("test");
		Sys.sleep(3);
		l.wait(3);
	}
	
}