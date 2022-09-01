
starting_shift = 0;
ending_shift = pi;
increment = pi/4;
%Flat guess 20pi/32 or 21pi/32
size = (ending_shift - starting_shift)/increment;
index = 0;
global graph_output;
graph_output = zeros(1+round(size),15);
x = zeros(1, round(size));
y = zeros(1, round(size));
for shift = starting_shift:increment:ending_shift
    index = index + 1;
    main_phase_shift(shift)
    global velocity_output;
    graph_output(1,:) = velocity_output(1,:);
    graph_output(index+1,:) = velocity_output(2,:);
end
for i = 2:6
    x = graph_output(1,:)
    y = graph_output(i,:)
    plot(x,y,'x-','LineWidth',3)
    title('Three Swimmers With Various Phase Shifts')
    xlabel('Phase Shift in Multiples of Pi')
    ylabel('Relative Velocity')
    hold on
end