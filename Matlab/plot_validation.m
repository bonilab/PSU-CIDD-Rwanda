% plot_validation.m
%
% Generate a scatter plot and PfPR versus either a cases per 1000 plot, or
% and incidence plot using the validation data provied. Note that the 
% function assumes that the data was generated by the getverificationstudy 
% script.
%
% Example: plot_validation('verification-data.csv', 'weighted_pfpr.csv', 'Burkina Faso', 'cases');

function [] = plot_validation(modelData, referenceData, country, type)
    subplot(1, 2, 1);
    plot_comparison(modelData, referenceData);
    
    subplot(1, 2, 2);
    if strcmp(type, 'cases')
        plot_cases_pfpr(modelData);   
    elseif strcmp(type, 'incidence')
        plot_pfpr_incidence(modelData);
    else
        error('Unknown plot type: %s', type);        
    end
    
    sgtitle(sprintf('%s Validation Metrics', country), 'FontSize', 20);
end

function [] = plot_comparison(modelData, referenceData)
    CSV_PFPR2TO10 = 8; CENTER_MIN = 0; CENTER_MAX = 80;
       

    % Load the data
    reference = csvread(referenceData);
    [data, districts] = load(modelData, 11 * 365, 16 * 365);
    
    % Since the MAP values are the mean, we want to compare against the
    % mean of our data, but highlight the seasonal minima and maxima
    hold on;
    for district = transpose(districts)
        expected = reference(reference(:, 1) == district, 2);
        pfpr = data(data(:, 2) == district, CSV_PFPR2TO10); 
        
        % We want the seasonal maxima, filter out the local maxima, once
        % this is done we should only have six points left
        maxima = pfpr(pfpr > mean(pfpr));
        maxima = maxima(maxima > maxima - std(maxima));
        maxima = findpeaks(maxima);
        
        % Repeat the same process for the minima as the maxima
        minima = pfpr(pfpr < mean(pfpr)) .* -1;
        minima = minima(minima > minima - std(minima));
        minima = findpeaks(minima);

        % Plot from the maxima to the minima, connected by a line
        line([expected expected], [mean(maxima) abs(mean(minima))], 'LineStyle', '--', 'LineWidth', 1.5, 'Color', 'black');
        scatter(expected, mean(maxima), 75, [99 99 99] / 255, 'filled', 'MarkerEdgeColor', 'black');
        scatter(expected, mean(pfpr), 150, [99 99 99] / 127.5, 'filled', 'MarkerEdgeColor', 'black');
        scatter(expected, abs(mean(minima)), 75, [99 99 99] / 255, 'filled', 'MarkerEdgeColor', 'black');
    end
    hold off;
    
    % Set the limits
    xlim([CENTER_MIN CENTER_MAX]);
    ylim([CENTER_MIN CENTER_MAX]);
    
    % Plot the reference error lines
    data = get(gca, 'YLim');
    for value = [0.9 0.95 1.05 1.1]
        line([data(1) data(2)], [data(1)*value data(2)*value], 'Color', [0.5 0.5 0.5], 'LineStyle', '-.');
    end
    line([data(1) data(2)], [data(1) data(2)], 'Color', 'black');
    text(data(2), data(2) + 0.5, '\pm0%', 'FontSize', 16);
    text(data(2), data(2) * 0.95, '-5%', 'FontSize', 16);
	text(data(2), data(2) * 0.9, '-10%', 'FontSize', 16);
    
    % Label and format the plot
    ylabel('Simulated {\itPf}PR_{2 to 10}');
    xlabel('Reference {\itPf}PR_{2 to 10}');
    format();
end

function [] = plot_cases_pfpr(modelData)
    CSV_POPULATION = 3; CSV_CASES = 4; CSV_REPORTED = 5; CSV_PFPR2TO10 = 8;
    TREATED = 0.832;

    % Load the data
    [data, districts] = load(modelData, 14 * 365, 15 * 365);
    
    % Prepare the arrays
    cases = zeros(size(districts, 1), 1);
    reported = zeros(size(districts, 1), 1);
    pfpr = zeros(size(districts, 1), 1);
    
    % Add the points
    ndx = 1;
    for district = transpose(districts)
        filtered = data(data(:, 2) == district, :);
        cases(ndx) = log10(sum(filtered(:, CSV_CASES)) / (max(filtered(:, CSV_POPULATION)) / 1000));
        reported(ndx) = log10((sum(filtered(:, CSV_REPORTED)) * TREATED) / (max(filtered(:, CSV_POPULATION)) / 1000));
        pfpr(ndx) = mean(filtered(:, CSV_PFPR2TO10));
        ndx = ndx + 1;
    end

    hold on;
    scatter(cases, pfpr, 'black', 'filled');
    scatter(reported, pfpr, 36, [99 99 99] / 127.5, 'filled', 'MarkerEdgeColor', 'black');    
    hold off;

    % Format the log10 axis
    ylim([0 80]);
    xlim(log10([250 1000]));
    xticks(log10(250:100:1000));
    xticklabels(split(num2str(250:100:1000)));
    
    % Label and format the plot
    xlabel('Clinical Cases per 1000');
    ylabel('Simulated {\itPf}PR_{2 to 10}');
    legend({'Total Clinical', 'Reported Clinical'}, 'Location', 'SouthEast');
    legend boxoff;
    format();
end

function [] = plot_pfpr_incidence(modelData)
    % Load the data
    [data, districts] = load(modelData, 14 * 365, 15 * 365);
    
    % Add the points
    hold on;
    for district = transpose(districts)
        filtered = data(data(:, 2) == district, :);
        incidence = sum(filtered(:, 4)) / max(filtered(:, 3));
        pfpr = mean(filtered(:, 7));
        scatter(pfpr, incidence, 'black', 'filled')
    end
    hold off;
    
    % Label and format the plot
    ylabel('Population Incidence (PYO^{-1})');
    xlabel('Simulated Prevalence ({\itPf}PR_{2 to 10})');
    format();
end

function [] = format()
    pbaspect([1 1 1]);
    graphic = gca;
    graphic.FontSize = 18;
end

function [data, districts] = load(filename, startDate, endDate)
    data = csvread(filename, 1, 0);
    data = data(data(:, 1) >= startDate, :);
    data = data(data(:, 1) <= endDate, :);
    districts = unique(data(:, 2));
end
