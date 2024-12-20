import Toybox.Activity;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.UserProfile;

class timerView extends WatchUi.DataField {

    hidden var _dur;
    hidden var myCounter;
    hidden var countDown;
    hidden var timerRunning; 
    hidden var targetHigh;
    hidden var targetLow;
    hidden var nextTargetHigh;
    hidden var nextTargetLow;
    hidden var label;
    hidden var fillColor;
    hidden var currentTargets as Array<Number> = new Array<Number>[2];
    hidden var nextTargets as Array<Number> = new Array<Number>[2];
    hidden var labelVertical;
    hidden var valueVertical;
    
    
    function initialize() {
        DataField.initialize();
        _dur = 0;
        myCounter = 0;
        countDown = 0;
        timerRunning = false;
        targetHigh = 0;
        targetLow = 0;
        nextTargetHigh = 0;
        nextTargetLow = 0;
        label = "workout timer";
        fillColor = Graphics.COLOR_TRANSPARENT;
        currentTargets = [] as Array<Number>;
        nextTargets = [] as Array<Number>;
        labelVertical  = -21;
        valueVertical = 0;
    }
    
    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info as Activity.Info) as Void {
        // compute is called every second and used only here for the countdown timer
        // backward countdown only if there a is fixed  duration of a lap / interval
        if (_dur > 0){
            countDown = (_dur - myCounter).abs();
        }
        // else we count upwards
        else {
            countDown = myCounter;
        }
        if (timerRunning) {
            myCounter++;
        }
        // reset after workout ends 
        if (Activity has :getCurrentWorkoutStep) {
            if (Activity.getCurrentWorkoutStep() == null){
                targetLow = 0;
                _dur = 0;
            }
        }
    }

    function onTimerStart() as Void {
        if (!timerRunning) {
            timerRunning = true;
        }
    }
    
    function onTimerStop() as Void {
        timerRunning = false;
    }

    function onTimerPause() as Void {
        timerRunning = false;
    }

    function onTimerResume() as Void {
        if (!timerRunning) {
            timerRunning = true;
        }
    }

    // added conditional to prevent zeroing on autolaps
    function onTimerLap() as Void {
        if (_dur == 0){
            myCounter = 0;
        }
    }

    function populateValues() as Void {
        var workoutStepInfo;
        var nextWorkoutStepInfo;
    
        if (Activity has :getCurrentWorkoutStep) {
            workoutStepInfo = Activity.getCurrentWorkoutStep();
            if (workoutStepInfo == null){
                _dur = 0;
                targetLow = 0;
                targetHigh = 0;
            }
            else {
                _dur = getDuration(workoutStepInfo);
                currentTargets = processStepInfo(workoutStepInfo);
                if (targetLow != null){
                    targetLow = currentTargets[0];
                }
                if (targetHigh !=null){
                    targetHigh = currentTargets[1];
                }
            }              
        }
        // repeat for nextStepInfo
        if (Activity has :getNextWorkoutStep) {
            nextWorkoutStepInfo = Activity.getNextWorkoutStep();
            if (nextWorkoutStepInfo == null){
                nextTargetLow = 0;
                nextTargetHigh = 0;
            }
            else {
                nextTargets = processStepInfo(nextWorkoutStepInfo);
                if (nextTargetLow != null){
                    nextTargetLow = nextTargets[0];
                }
                if (nextTargetHigh != null){
                    nextTargetHigh = nextTargets[1];
                }
            }
        }
    }
    
    
    function onWorkoutStarted() as Void {
        myCounter = 0;
        //getZones(); leave out in production
        populateValues();
    }

    function onWorkoutStepComplete() as Void {
        myCounter = 0;
        populateValues();
    }
    
    function secondsToTimeString(totSeconds) {
        // format for countdown timer
        var hours = (totSeconds / 3600).toNumber();
        var minutes = ((totSeconds - hours * 3600) / 60).toNumber();
        var seconds = totSeconds - hours * 3600 - minutes * 60;
        var timeString = Lang.format("$1$:$2$:$3$", [ 
                                        hours.format("%01d"), 
                                        minutes.format("%02d"), 
                                        seconds.format("%02d") 
                                        ]); 
        return timeString;
    }

    (:regularVersion)
    function setfillColor() { 
        if (nextTargetLow < targetLow) {
            return Graphics.COLOR_RED;
        }
        else {
            return Graphics.COLOR_GREEN;
        }
    }
    (:regularVersion)
    function setVerticalValues(){
        labelVertical = -21;
        valueVertical = 0;
        return;
    }

    (:edge130plusVersion)
    function setfillColor(){
        return Graphics.COLOR_TRANSPARENT;
    }

    (:edge130plusVersion)
    function setVerticalValues(){
        labelVertical = -42;
        valueVertical = -10;
        return;
    }

    (:edge1050Version)
    function setfillColor() { 
       if (nextTargetLow < targetLow) {
        return Graphics.COLOR_RED;
        }
        else {
            return Graphics.COLOR_GREEN;
        }
    }
    
    (:edge1050Version)
    function setVerticalValues(){
        labelVertical = -62;
        valueVertical = -1;
        return;
    }

    (:edge1030Version)
    function setVerticalValues(){
        labelVertical = -32;
        valueVertical = -10;
        return;
    }

    (:edge1030Version)
    function setfillColor() { 
        if (nextTargetLow < targetLow) {
            return Graphics.COLOR_RED;
        }
        else {
            return Graphics.COLOR_GREEN;
        }
    }


    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var textCenter = Toybox.Graphics.TEXT_JUSTIFY_CENTER;
        var backgroundColor = getBackgroundColor();
        var highLowString = Lang.format("$1$ - $2$", [targetLow, targetHigh]);
        var value = secondsToTimeString(countDown);
        setVerticalValues();
    
        // set background color
        dc.setColor(Graphics.COLOR_TRANSPARENT, backgroundColor);
        
        // set the label as target info if available.
        if (targetLow == 0) {
            label = "workout timer";
        }
        else {
            label = highLowString;
        }
        // do layout, first clean background effect just to be sure
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle (0, 0, width, height);
        // check values before background effect
        if (_dur > 0 && countDown == 13){
            populateValues();
        }
        // set background effect color, just before its starts
        else if (_dur > 0 && countDown == 12){
            fillColor = setfillColor();
        }
        // then let it roll
        else if (_dur > 0 && countDown < 11){
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle (2, 2, (width * (10 - countDown)/9) - 4, height - 4);
        }

        // set foreground color
        if (backgroundColor ==  Graphics.COLOR_BLACK) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);    
        } 
        else {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        }
        // write the text in foreground color
        dc.drawText(width / 2, (height / 2) + labelVertical, Toybox.Graphics.FONT_MEDIUM, label, textCenter);
        dc.drawText(width / 2, (height / 2) + valueVertical, Toybox.Graphics.FONT_LARGE, value, textCenter);   
    }


    function correctTargets(target) as Number {
        // custom power values are represented in .fit files as power + 1000W
        if (target > 1000){
            return target - 1000;
        }
        // custom Heart rates are respresented as bpm + 100
        if (target > 150){
            return target - 100;
        }
        if (target > 0) {
            return target;
        } 
        else {
            return 0;
        }
    }

    function processStepInfo(thisOrNextStepinfo){
        var low = 0;
        var tHigh = 0;
        var tLow = 0;
        if (checkStepInfo(thisOrNextStepinfo) && thisOrNextStepinfo.step.targetValueLow != null ){
            tHigh = correctTargets(thisOrNextStepinfo.step.targetValueHigh);
            tLow = correctTargets(thisOrNextStepinfo.step.targetValueLow);

            // heart rate zone == targetValueLow :rolling_eyes:
            low = thisOrNextStepinfo.step.targetValueLow;
            if (low > 0 and low < 6 ) {
                if (UserProfile has :getCurrentSport) {
                    var sport = UserProfile.getCurrentSport();
                    if (UserProfile has :getHeartRateZones){
                        var heartRateZones = UserProfile.getHeartRateZones(sport);
                        tLow = heartRateZones[low - 1];
                        tHigh = heartRateZones[low];
                    }                                      
                } 
            }    
        }
        return [tLow, tHigh] as Array<Number>;
    }


    function getDuration(workoutStepInfo) as Number {
        // set the duration of the workout steps
        if (!(checkStepInfo(workoutStepInfo))) {
            return 0;
        } 
        if (workoutStepInfo.step.durationValue == null){
            return 0;
        }
        // check for durationType is time (with value 0) or open (value 5)
        if (!((workoutStepInfo.step.durationType == 0) or (workoutStepInfo.step.durationType == 5))) {
            return 0;
        }
        else {
            return workoutStepInfo.step.durationValue;
        }
    }

    function checkStepInfo(stepInfo) as Boolean {
        if (stepInfo == null){
            return false;
        }
        if (!(stepInfo has :step)){
            return false;
        }
        if (!(stepInfo.step instanceof Activity.WorkoutStep)){
            return false;
        }
        else {
            return true;
        }
    }

} 