global values;
values = zeros(6,3);
%zeros(number of phase shifts + 1, number of separations)
index = 1;
labels = zeros(5);
global velocity_output;
for i = 0:pi/4:pi
    index = index + 1;
    run(i, false);
    values(1,:) = velocity_output(1,:);
    values(index,:) = velocity_output(2,:);
    labels(index-1) = i;
end
for i = 2:6
    plot(values(1,:), values(i,:),'x-','LineWidth', 3);
    hold on
end
xlabel('Separation')
ylabel('Velocity')
legend('0','pi/4','pi/2','3pi/4','pi')