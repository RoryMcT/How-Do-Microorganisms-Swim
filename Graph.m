main_phase_shift(5*pi/8)
for i = 2:6
    x = graph_output(1,:)
    y = graph_output(i,:)
    plot(x,y,'x-','LineWidth',3)
    if i == 4
       hold on
       x = velocity_output(1,:);
       y = velocity_output(2,:);
       plot(x,y,'x-','LineWidth',3)
    end
    
    title('Three Swimmers With Various Phase Shifts')
    xlabel('Seperation (bodylengths)')
    ylabel('Relative Velocity')
    hold on
end
hold on
legend('0','pi/4','pi/2', '5pi/8', '3pi/4','pi')