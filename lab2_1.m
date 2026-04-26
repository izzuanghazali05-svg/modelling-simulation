% =========================================================
% Transport Mode Choice Probability Calculator
% Using Utility Function + Multinomial Logit Model
% Modes: Self-Driving, E-Hailing, Public Transport, Carpool
% =========================================================

clc;
clear;

modes = {'Self-Driving', 'E-Hailing', 'Public Transport', 'Carpool'};
num_modes = length(modes);
criteria = {'Driving Experience', 'Journey Quality', 'Food Availability', 'Cost Affordability'};

% ---------------------------------------------------------
% STEP 1: Get number of respondents
% ---------------------------------------------------------
fprintf('===========================================\n');
fprintf('  TRANSPORT MODE CHOICE PROBABILITY TOOL  \n');
fprintf('===========================================\n\n');

n = input('How many respondents are there? ');
while ~isnumeric(n) || n < 1 || floor(n) ~= n
  fprintf('Please enter a valid positive integer.\n');
  n = input('How many respondents are there? ');
end

% ---------------------------------------------------------
% STEP 2: Per respondent — RANKING first, then RATINGS
% ---------------------------------------------------------
% all_ranks(respondent, criterion)     — rank 1 to 4, no repeats
% ratings(respondent, mode, criterion) — rating 1 to 5
all_ranks = zeros(n, 4);
ratings   = zeros(n, num_modes, 4);

for i = 1:n
  fprintf('==========================================\n');
  fprintf('  RESPONDENT %d of %d\n', i, n);
  fprintf('==========================================\n\n');

  % --- RANKING (1-4, unique per person) ---
  fprintf('  STEP A: Rank the 4 criteria by importance\n');
  fprintf('  Assign each a unique rank from 1 to 4.\n');
  fprintf('  (1 = most important, 4 = least important)\n\n');

  used = [];
  person_ranks = zeros(1, 4);
  for c = 1:4
    while true
      avail = setdiff(1:4, used);
      fprintf('  Available ranks: %s\n', num2str(avail));
      prompt = sprintf('  Rank for %-22s: ', criteria{c});
      val = input(prompt);
      if ~isnumeric(val) || ~ismember(val, avail)
        fprintf('  Invalid! Please choose from available ranks only.\n');
      else
        person_ranks(c) = val;
        used = [used val];
        break;
      end
    end
  end
  all_ranks(i, :) = person_ranks;
  fprintf('\n');

  % --- RATINGS per mode (1-5) ---
  fprintf('  STEP B: Rate each transport mode (1=Very Poor, 5=Excellent)\n\n');
  for m = 1:num_modes
    fprintf('  Mode: %s\n', modes{m});
    for c = 1:4
      prompt = sprintf('    %-26s (1-5): ', criteria{c});
      val = input(prompt);
      while ~isnumeric(val) || val < 1 || val > 5
        fprintf('    Please enter a value between 1 and 5.\n');
        val = input(prompt);
      end
      ratings(i, m, c) = val;
    end
  end
  fprintf('\n');
end

% ---------------------------------------------------------
% STEP 3: Calculate average weight per criterion
% avg_weight(c) = sum of all ratings for criterion c
%                 / (rank_of_c_per_person × n)  <- summed across persons
%
% Formula: avg_weight(c) = sum_i[ rating_sum_across_modes(i,c) ]
%                          / ( sum_i[ rank(i,c) ] * n )
% Simplified per spec: sum(ratings) / (rank * n)
% Here we use each person's own rank in the denominator:
% avg_weight(c) = ( sum over all respondents of their total rating for c )
%                 / ( sum over all respondents of rank(i,c) * n )
% ---------------------------------------------------------

% sum of ratings across ALL modes per respondent per criterion
% rating_sum(i,c) = sum over modes of ratings(i, :, c)
rating_sum = zeros(n, 4);
for i = 1:n
  for c = 1:4
    rating_sum(i, c) = sum(ratings(i, :, c));
  end
end

% avg_weight(c) = sum_i( rating_sum(i,c) ) / ( sum_i( rank(i,c) ) * n )
avg_weights = zeros(1, 4);
for c = 1:4
  numerator   = sum(rating_sum(:, c));
  denominator = sum(all_ranks(:, c)) * n;
  avg_weights(c) = numerator / denominator;
end

fprintf('--- Average Weights per Criterion ---\n');
fprintf('  Formula: sum(ratings) / (sum(ranks) x n)\n\n');
for c = 1:4
  fprintf('  w(%s) = %.4f\n', criteria{c}, avg_weights(c));
end
fprintf('\n');

% ---------------------------------------------------------
% STEP 4: Calculate average ratings per mode per criterion
% ---------------------------------------------------------
avg_ratings = zeros(num_modes, 4);
for m = 1:num_modes
  for c = 1:4
    avg_ratings(m, c) = mean(ratings(:, m, c));
  end
end

fprintf('--- Average Ratings per Mode ---\n');
fprintf('%-20s %20s %18s %20s %22s\n', 'Mode', criteria{1}, criteria{2}, criteria{3}, criteria{4});
fprintf('%s\n', repmat('-', 1, 85));
for m = 1:num_modes
  fprintf('%-20s %20.3f %18.3f %20.3f %22.3f\n', modes{m}, ...
    avg_ratings(m,1), avg_ratings(m,2), avg_ratings(m,3), avg_ratings(m,4));
end

% ---------------------------------------------------------
% STEP 5: Compute utility U(j) for each mode
% U(j) = sum over c of [ avg_weight(c) * avg_rating(mode, c) ]
% ---------------------------------------------------------
U = zeros(1, num_modes);
for m = 1:num_modes
  U(m) = sum(avg_weights .* avg_ratings(m, :));
end

fprintf('\n--- Utility Formula: U(j) = sum[ avg_weight(c) x avg_rating(j,c) ] ---\n');
for m = 1:num_modes
  fprintf('  U(%s) = %.4f\n', modes{m}, U(m));
end

% ---------------------------------------------------------
% STEP 6: Multinomial Logit — Pj = exp(Uj) / sum(exp(Uk))
% ---------------------------------------------------------
exp_U = exp(U);
total_exp = sum(exp_U);
P = exp_U / total_exp;

fprintf('\n--- Choice Probabilities (Multinomial Logit) ---\n');
for m = 1:num_modes
  fprintf('  P(%s) = %.4f  (%.2f%%)\n', modes{m}, P(m), P(m)*100);
end

% ---------------------------------------------------------
% STEP 7: Bar Chart Output
% ---------------------------------------------------------
figure('Name', 'Transport Mode Choice Probabilities', 'NumberTitle', 'off', ...
       'Position', [100, 100, 750, 500]);

bar_colors = [0.22 0.49 0.72;   % blue  - Self-Driving
              0.30 0.69 0.29;   % green - E-Hailing
              0.89 0.46 0.13;   % orange - Public Transport
              0.60 0.31 0.64];  % purple - Carpool

b = bar(P * 100, 'FaceColor', 'flat');
for m = 1:num_modes
  b.CData(m, :) = bar_colors(m, :);
end

set(gca, 'XTickLabel', modes, 'FontSize', 11, 'FontName', 'Arial');
xtickangle(15);
ylabel('Probability (%)', 'FontSize', 12);
title('Transport Mode Choice Probabilities', 'FontSize', 14, 'FontWeight', 'bold');
ylim([0 max(P*100) * 1.25 + 5]);
grid on;
box off;

% Add value labels on top of each bar
for m = 1:num_modes
  text(m, P(m)*100 + 1.2, sprintf('%.2f%%', P(m)*100), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
end

fprintf('\nBar chart displayed successfully.\n');
fprintf('===========================================\n');
fprintf('           CALCULATION COMPLETE           \n');
fprintf('===========================================\n');
