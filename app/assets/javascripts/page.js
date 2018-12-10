(function() {
  App.room = App.cable.subscriptions.create("WebNotificationsChannel", {
    received: function(data) {
      console.log('ssss');
      return $('#notification-count').text(" students " + data['message']);
    }
  });

}).call(this);
(function() {
  App.room = App.cable.subscriptions.create("NotificationsChannel", {
    received: function(data) {
      console.log(data);
      $("#notification_count").text(data['count'])
      $('title').text('Sample Application '+ data['unread_notification']+ ' Notification Unread')
      $("#notification").prepend('<li><a href="'+data['url']+'">'+data['value']['title']+' created at '+data['time_ago']+'</a></li>');
      $('.pos-demo').notify("New Notification Created", "success");
      notification_audio();
    }
  });

}).call(this);
function notification_audio(){
  var mp3Source = '<source src="to-the-point.mp3" type="audio/mpeg">';
  var oggSource = '<source src="to-the-point.ogg" type="audio/ogg">';
  var embedSource = '<embed hidden="true" autostart="true" loop="false" src="to-the-point.mp3">';
  document.getElementById("sound").innerHTML='<audio autoplay="autoplay">' + mp3Source + embedSource + '</audio>';
}