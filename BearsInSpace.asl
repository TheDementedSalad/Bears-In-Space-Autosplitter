// Made by Nikoehart & TheDementedSalad
// Big shoutouts to the Ero for assistance within the Items logic and splitting
// Shoutouts to Rumii & Hntd for their assistance within for all the efforts of finding some of the values needed 
state("BearsInSpace-Win64-Shipping") {}

startup
{
	Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.GameName = "Bears In Space";
	vars.Helper.StartFileLogger("BiS_Log.txt");
	
	vars.CompletedSplits = new HashSet<string>();
	
	settings.Add("Ch", false, "Chapter Splits");
	settings.Add("Final", true, "Final Split (Always Active)");
}

init
{
	IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 05 ???????? 48 3B C? 48 0F 44 C? 48 89 05 ???????? E8");
	IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
	IntPtr Cutscene = vars.Helper.ScanRel(3, "48 8b 05 ?? ?? ?? ?? 44 39 6c 03");

	if (gWorld == IntPtr.Zero || gEngine == IntPtr.Zero || Cutscene == IntPtr.Zero)
	{
		const string Msg = "Not all required addresses could be found by scanning.";
		throw new Exception(Msg);
	}

	vars.Helper["Loading"] = vars.Helper.Make<bool>(gEngine, 0xCE8, 0xB8, 0x18, 0x0, 0x150, 0x438);
	vars.Helper["Paused"] = vars.Helper.Make<byte>(gEngine, 0xCE8, 0xB8, 0x18, 0x0, 0x150, 0x408);
	vars.Helper["LevelEnd"] = vars.Helper.MakeString(gEngine, 0xCE8, 0xB8, 0x18, 0x0, 0x150, 0x520, 0x0);
	vars.Helper["LevelEnd"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	vars.Helper["Cutsc"] = vars.Helper.Make<bool>(Cutscene, 0x98, 0x50, 0x0, 0x1A0);
	vars.Helper["Map"] = vars.Helper.MakeString(gEngine, 0xAF8, 0x28);
	vars.Helper["Final"] = vars.Helper.MakeString(gWorld, 0x30, 0x98, 0x520, 0x2F0, 0x510, 0x0);
}

update
{
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	var world = current.Map;
	if (!string.IsNullOrEmpty(world) && world != "None")
		current.World = world;
	
	// Debug. Comment out before release.
    if (old.Map != current.Map)
        vars.Log(old.World + " -> " + current.World);
}

onStart
{
	vars.CompletedSplits.Clear();
	
	// This makes sure the timer always starts at 0.00
	timer.IsGameTimePaused = true;
}

start
{
	return current.World == "Intro" && !current.Cutsc && old.Cutsc;
}

split
{
	if(settings["Ch"] && current.World != old.World && (current.World != "MainMenu" || old.World != "MainMenu") && vars.CompletedSplits.Add(current.World)){
		return true;
	}
	
	if(current.Final == "SEQ_BearShipLeave" && old.Final != "SEQ_BearShipLeave"){
		return true;
	}
}

isLoading
{
	return !current.Loading || current.Paused != 0 || current.Cutsc || !string.IsNullOrEmpty(current.LevelEnd);
}

reset
{
}

exit
{
    //pauses timer if the game crashes
    timer.IsGameTimePaused = true;
}
