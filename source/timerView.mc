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
    
    function initialize() {
        DataField.initialize();
        _dur = 0;
        myCounter = 0;
        countDown = 0;
        timerRunning = false;
        targetHigh = 0;
        targetLow = 0;
    }
    
    //  Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc as Dc) as Void {
        // Use the generic, centered layout
        View.setLayout(Rez .Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        labelView.locY = labelView.locY - 20;
        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY + 9;
        
        (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
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
        if (Activity has :getCurrentWorkoutStep) {
            var workoutStepInfo = Activity.getCurrentWorkoutStep();
            var type = workoutStepInfo.step.targetType.toString().toNumber();
            // type 1 == WORKOUT_STEP_TARGET_HEART_RATE
            if (type != 1){
                if (workoutStepInfo.step.durationValue != null){
                    _dur = workoutStepInfo.step.durationValue; 
                }
                else {
                    _dur = 0;
                }
                // power targets in workout .fit files are represented as power-in-watts + 1000
                if (workoutStepInfo.step.targetValueHigh > 1000){
                    targetHigh = workoutStepInfo.step.targetValueHigh - 1000;
                }
                else if (workoutStepInfo.step.targetValueHigh > 10){
                    targetHigh = workoutStepInfo.step.targetValueHigh;
                }
                else {
                    targetHigh = 0;
                }
                if (workoutStepInfo.step.targetValueLow > 1000){
                    targetLow = workoutStepInfo.step.targetValueLow - 1000;
                }
                // it seems that if target type = 7 workoutStepInfo.step.targetValueLow is used for 
                // power zones but we can not reach this through the Toybox API.
                else if (workoutStepInfo.step.targetValueLow > 10){
                    targetLow = workoutStepInfo.step.targetValueLow;
                }
                else {
                    targetLow = 0;
                }
            }
            // target type is 1 == heart_rate:
            // heart rate zone == targetValueLow :rolling_eyes:
            else {
                if (workoutStepInfo.step.durationValue != null){
                    _dur = workoutStepInfo.step.durationValue; 
                }
                else {
                    _dur = 0;
                }
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
                        }
                    } 
                }
                else {
                    if (workoutStepInfo.step.targetValueLow != null){
                        targetLow = workoutStepInfo.step.targetValueLow;
                    }
                    else {
                        targetLow = 0;
                    }
                    if (workoutStepInfo.step.targetValueHigh != null){
                        targetHigh = workoutStepInfo.step.targetValueHigh;
                    }
                    else {
                        targetHigh = 0;
                    }
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

    // This will be called once a second when the data field is visible.
    function onUpdate(dc as Dc) as Void {
    
        // Set the background color
        (View.findDrawableById("Background") as Text).setColor(getBackgroundColor());

        // Set the foreground color and value, added the label in same color
        var value = View.findDrawableById("value") as Text;
        var label = View.findDrawableById("label") as Text;
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
            label.setColor(Graphics.COLOR_WHITE);
        } 
        else {
            value.setColor(Graphics.COLOR_BLACK);
            label.setColor(Graphics.COLOR_BLACK);
        }
           
        var highLowString = Lang.format("$1$ - $2$", [targetLow, targetHigh]);
        value.setText(secondsToTimeString(countDown));
        if (targetLow == 0){
            (View.findDrawableById("label") as Text).setText(Rez.Strings.label);
        }
        else {
            (View.findDrawableById("label") as Text).setText(highLowString);
        }
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }
}
