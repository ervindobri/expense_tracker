enum ReminderFrequency {
  daily, weekly, monthly, none
}


extension Ext on ReminderFrequency {
  String get display => switch(this){
    ReminderFrequency.daily => 'Daily',
    ReminderFrequency.weekly => 'Weekly',
    ReminderFrequency.monthly => 'Monthly',
    ReminderFrequency.none => 'None',
  };
}