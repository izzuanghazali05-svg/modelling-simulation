clc;
clear;
close all;

programmes = {'Pure Sciences', 'Applied Sciences', 'Engineering', ...
              'Accounting', 'Management', 'Arts'};

factors = {'Interest', 'Exam Results', 'Career', ...
           'Location', 'Fees', 'Explore'};

num_prog   = length(programmes);
num_factor = length(factors);

% ---------------------------------------------------------
% DEFAULT ratings from Table 1 (assignment)
% rows = programmes, cols = factors
% ---------------------------------------------------------
default_ratings = [
  5, 5, 3, 3, 4, 2;   % Pure Sciences
  4, 5, 4, 3, 3, 3;   % Applied Sciences
  4, 5, 5, 2, 5, 2;   % Engineering
  3, 4, 4, 4, 4, 2;   % Accounting
  3, 3, 3, 5, 3, 3;   % Management
  2, 3, 2, 4, 2, 4    % Arts
];

% DEFAULT weights from Table 2 (assignment)
default_weights = [0.30, 0.20, 0.25, 0.10, 0.10, 0.05];

fprintf('==============================================\n');
fprintf('  PROGRAMME CHOICE PROBABILITY CALCULATOR   \n');
fprintf('  Discrete Choice Model (Multinomial Logit) \n');
fprintf('==============================================\n\n');

% ---------------------------------------------------------
% STEP 1: Ask user if they want to use default values
%         or enter custom ones
% ---------------------------------------------------------
fprintf('Would you like to:\n');
fprintf('  [1] Use default values from the assignment table\n');
fprintf('  [2] Enter your own ratings and weights\n\n');

choice = input('Enter your choice (1 or 2): ');
while ~isnumeric(choice) || ~ismember(choice, [1 2])
  fprintf('Please enter 1 or 2.\n');
  choice = input('Enter your choice (1 or 2): ');
end

if choice == 1
  ratings = default_ratings;
  weights = default_weights;
  fprintf('\nUsing default values from assignment table.\n\n');

else
  % ---------------------------------------------------------
  % STEP 2a: Enter custom ratings (1-5 per programme per factor)
  % ---------------------------------------------------------
  ratings = zeros(num_prog, num_factor);

  fprintf('\n--- Enter ratings for each programme (1 = very low, 5 = very high) ---\n\n');

  for p = 1:num_prog
    fprintf('Programme: %s\n', programmes{p});
    for f = 1:num_factor
      prompt = sprintf('  %-15s (1-5): ', factors{f});
      val = input(prompt);
      while ~isnumeric(val) || val < 1 || val > 5 || floor(val) ~= val
        fprintf('  Please enter a whole number between 1 and 5.\n');
        val = input(prompt);
      end
      ratings(p, f) = val;
    end
    fprintf('\n');
  end

  % ---------------------------------------------------------
  % STEP 2b: Enter custom weights (must sum to 1.00)
  % ---------------------------------------------------------
  fprintf('--- Enter importance weights for each factor ---\n');
  fprintf('    Weights must sum to 1.00\n\n');

  weights = zeros(1, num_factor);
  for f = 1:num_factor
    prompt = sprintf('  Weight for %-15s (0 to 1): ', factors{f});
    val = input(prompt);
    while ~isnumeric(val) || val < 0 || val > 1
      fprintf('  Please enter a value between 0 and 1.\n');
      val = input(prompt);
    end
    weights(f) = val;
  end

  total_w = sum(weights);
  if abs(total_w - 1.0) > 0.01
    fprintf('\nWarning: weights sum to %.4f, not 1.00.\n', total_w);
    fprintf('Normalising weights automatically...\n');
    weights = weights / total_w;
  end
  fprintf('\n');
end

% ---------------------------------------------------------
% STEP 3: Display ratings table
% ---------------------------------------------------------
fprintf('==============================================\n');
fprintf('  RATINGS TABLE\n');
fprintf('==============================================\n');
fprintf('%-18s', 'Programme');
for f = 1:num_factor
  fprintf('%-14s', factors{f});
end
fprintf('\n%s\n', repmat('-', 1, 18 + 14*num_factor));

for p = 1:num_prog
  fprintf('%-18s', programmes{p});
  for f = 1:num_factor
    fprintf('%-14d', ratings(p, f));
  end
  fprintf('\n');
end
fprintf('\n');

% ---------------------------------------------------------
% STEP 4: Display weights
% ---------------------------------------------------------
fprintf('==============================================\n');
fprintf('  IMPORTANCE WEIGHTS\n');
fprintf('==============================================\n');
for f = 1:num_factor
  fprintf('  w(%-15s) = %.2f\n', factors{f}, weights(f));
end
fprintf('  Total weight = %.2f\n\n', sum(weights));

% ---------------------------------------------------------
% STEP 5: Compute utility for each programme
% U(j) = sum of [ weight(f) x rating(j,f) ] for all f
% ---------------------------------------------------------
U = zeros(1, num_prog);
for p = 1:num_prog
  U(p) = sum(weights .* ratings(p, :));
end

fprintf('==============================================\n');
fprintf('  UTILITY SCORES\n');
fprintf('  Formula: U(j) = sum[ w(f) x rating(j,f) ]\n');
fprintf('==============================================\n');
for p = 1:num_prog
  fprintf('  U(%-18s) = %.4f\n', programmes{p}, U(p));
end
fprintf('\n');

% ---------------------------------------------------------
% STEP 6: Multinomial Logit
% P(j) = exp(U(j)) / sum( exp(U(k)) ) for all k
% ---------------------------------------------------------
exp_U     = exp(U);
sum_exp_U = sum(exp_U);
P         = exp_U / sum_exp_U;

fprintf('==============================================\n');
fprintf('  CHOICE PROBABILITIES (Multinomial Logit)\n');
fprintf('  Formula: P(j) = exp(U(j)) / sum(exp(U(k)))\n');
fprintf('==============================================\n');
for p = 1:num_prog
  fprintf('  P(%-18s) = %.4f  (%.2f%%)\n', programmes{p}, P(p), P(p)*100);
end
fprintf('\n');

% ---------------------------------------------------------
% STEP 7: Identify top predicted programme
% ---------------------------------------------------------
[max_prob, top_idx] = max(P);
fprintf('==============================================\n');
fprintf('  TOP PREDICTED CHOICE\n');
fprintf('==============================================\n');
fprintf('  Programme  : %s\n', programmes{top_idx});
fprintf('  Probability: %.2f%%\n\n', max_prob * 100);

% ---------------------------------------------------------
% STEP 8: Bar chart
% ---------------------------------------------------------
bar_colors = [
  0.11, 0.62, 0.47;   % teal         - Pure Sciences
  0.22, 0.49, 0.72;   % blue         - Applied Sciences
  0.84, 0.35, 0.18;   % orange-red   - Engineering
  0.73, 0.46, 0.10;   % brown        - Accounting
  0.48, 0.32, 0.64;   % purple       - Management
  0.83, 0.33, 0.49    % pink         - Arts
];

figure('Name', 'Programme Choice Probabilities', ...
       'NumberTitle', 'off');

b = bar(P * 100);

ch = get(b, 'children');
for i = 1:num_prog

    set(b, 'FaceColor', 'flat');

end

set(gca, 'XTickLabel', programmes);
set(gca, 'XTick', 1:num_prog);
xtickangle(20);
ylabel('Probability (%)');
xlabel('Undergraduate Programme');
title('Aiman''s Predicted Programme Choice');

ylim([0, max(P * 100) * 1.3]);
grid on;

for p = 1:num_prog
  text(p, P(p)*100 + 1.0, sprintf('%.2f%%', P(p)*100), ...
    'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

fprintf('Bar chart displayed.\n');
fprintf('==============================================\n');
fprintf('              SIMULATION COMPLETE            \n');
fprintf('==============================================\n');
