module EventSystem
  module Helper
    def integrate_event_system
      if controller.class.method_defined?("updates_for_#{action_name}")
        url = url_for :controller => controller_name, :action => "updates_for_#{action_name}"
        interval = controller.event_system_update_interval

        "<span id='event_system_last_load' style='display: none;'>#{@controller.current_event_number = EventSystem::IndicatorSequence.current}</span>"+
        javascript_tag(
          "function getNewEvents(url) {
             url = url+'?last_load='+$('#event_system_last_load').text();
             $.getScript(url);
           };
           setInterval(function() {getNewEvents('#{url}');}, #{interval*1000});")+
      else
        ""
      end
    end
  end
end
