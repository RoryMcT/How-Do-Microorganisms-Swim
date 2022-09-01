global velocity_output
x = zeros(1,17);
y = zeros(1,17);
index = 0;
for channel_width = 0.4:0.1:2
    index = index+1;
    run(channel_width)
    x(index) = channel_width;
    y(index) = velocity_output(2);
end

plot(x,y,'x-','LineWidth',3)
xlabel('Channel width (bodylengths)')
ylabel('Relative velocity')
title('Swimmers in channels of various widths')