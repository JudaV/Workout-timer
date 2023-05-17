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
    hidden var value;
    hidden var fillColor;
    
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
        value = 0;
        label = "workout timer";
        fillColor = Graphics.COLOR_TRANSPARENT;
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
        if (Activity.getCurrentWorkoutStep() == null){
            targetLow = 0;
            _dur = 0;
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
        var low = 0;
        var nextLow = 0;
        var workoutStepInfo;
        var nextWorkoutStepInfo;
    
        if (Activity has :getCurrentWorkoutStep) {
            workoutStepInfo = Activity.getCurrentWorkoutStep();
            if (workoutStepInfo != null) {
                if (workoutStepInfo has : step) {
                    if (workoutStepInfo.step instanceof Activity.WorkoutStep){
                        targetHigh = workoutStepInfo.step.targetValueHigh;
                        targetLow = workoutStepInfo.step.targetValueLow;
                        // set the duration of the workout steps
                        if (workoutStepInfo.step.durationValue != null){
                            _dur = workoutStepInfo.step.durationValue; 
                        }
                        else {
                            _dur = 0;
                        }
                        // power targets in workout .fit files are represented as power-in-watts + 1000
                        if (targetHigh > 1000){
                            targetHigh = targetHigh - 1000;
                        }
                        // custom Heart rates are respresented as bpm + 100
                        else if (targetHigh > 150){
                            targetHigh = targetHigh - 100
                        }
                        else if (targetHigh > 7) {
                            targetHigh = targetHigh;
                        } 
                        else {
                            targetHigh = 0;
                        }

                        // it seems that if target type = 7 workoutStepInfo.step.targetValueLow is used for 
                        // power zones but we can not reach this through the Toybox API.
                        if (targetLow > 1000){
                            targetLow = targetLow - 1000;
                        }
                        else if (targetLow > 150){
                            targetLow = targetLow - 100
                        }
                        else if (targetLow > 7){
                            targetLow = targetLow;
                        }
                        // heart rate zone == targetValueLow :rolling_eyes:
                        else if (targetLow > 0 and targetLow < 6 ) {
                            if (UserProfile has :getCurrentSport) {
                                var sport = UserProfile.getCurrentSport();
                                if (UserProfile has :getHeartRateZones){
                                    var heartRateZones = UserProfile.getHeartRateZones(sport);
                                    if (workoutStepInfo.step.targetValueLow != null){
                                        low = workoutStepInfo.step.targetValueLow; 
                                        if (low > 0 and low < 6){
                                            targetLow = heartRateZones[low - 1];
                                            targetHigh = heartRateZones[low];
                                        }
                                        else {
                                            targetLow = workoutStepInfo.step.targetValueLow;
                                            targetHigh = workoutStepInfo.step.targetValueHigh;
                                        }
                                    }
                                } 
                            }
                        }
                        else {
                            targetLow = 0;
                        }
                    }
                }
            }
            else {
                targetLow = 0;
                targetHigh = 0;
            }
        }
        // repeat for nextStepInfo - if-else nightmare
        if (Activity has :getNextWorkoutStep) {
            nextWorkoutStepInfo = Activity.getNextWorkoutStep();
            if (nextWorkoutStepInfo != null){
                if (nextWorkoutStepInfo has : step) {
                    if (nextWorkoutStepInfo.step instanceof Activity.WorkoutStep) {
                        nextTargetHigh = nextWorkoutStepInfo.step.targetValueHigh;
                        nextTargetLow = nextWorkoutStepInfo.step.targetValueLow;
                        if (nextTargetHigh > 1000){
                            nextTargetHigh = nextTargetHigh - 1000;
                        }
                        else if (nextTargetHigh > 150){
                            nextTargetHigh = nextTargetHigh - 100
                        }
                        else if (nextTargetHigh > 10) {
                            nextTargetHigh = nextTargetHigh;
                        }
                        else if (nextTargetHigh > 0) {
                        }
                        else {
                            nextTargetHigh = 0;
                        }
                        if (nextTargetLow > 1000){
                            nextTargetLow = nextTargetLow - 1000;
                        }
                        else if (nextTargetLow > 150){
                            nextTargetLow = nextTargetLow - 100
                        }
                        else if (nextTargetLow > 10){
                            nextTargetLow = nextTargetLow;
                        }
                        else if (nextTargetLow > 0){
                            if (UserProfile has :getCurrentSport) {
                            var sport = UserProfile.getCurrentSport();
                            if (UserProfile has :getHeartRateZones){
                                var heartRateZones = UserProfile.getHeartRateZones(sport);
                                if (nextWorkoutStepInfo.step.targetValueLow != null){
                                    nextLow = nextWorkoutStepInfo.step.targetValueLow; 
                                    if (nextLow > 0 and nextLow < 6){
                                        nextTargetLow = heartRateZones[nextLow - 1];
                                        nextTargetHigh = heartRateZones[nextLow];
                                    }
                                    else {
                                        nextTargetLow = nextWorkoutStepInfo.step.targetValueLow;
                                        nextTargetHigh = nextWorkoutStepInfo.step.targetValueHigh;
                                    }
                                }    
                            }
                        }
                    }
                }
            }
        }
        else {
            nextTargetLow = 0;
            nextTargetHigh = 0;
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

    (:edge130plusVersion)
    function setfillColor(){
        return Graphics.COLOR_TRANSPARENT;
    }
    

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var textCenter = Toybox.Graphics.TEXT_JUSTIFY_CENTER | Toybox.Graphics.TEXT_JUSTIFY_VCENTER;
        var backgroundColor = getBackgroundColor();
        var highLowString = Lang.format("$1$ - $2$", [targetLow, targetHigh]);
        value = secondsToTimeString(countDown);
    
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
        dc.drawText(width / 2, height / 2 - 21, Toybox.Graphics.FONT_MEDIUM, label, textCenter);
        dc.drawText(width / 2, height / 2 + 11, Toybox.Graphics.FONT_LARGE, value, textCenter);   
    }
}