function DateNumber = m2xdate(MATLABDateNumber, Convention)
%M2XDATE MATLAB Serial Date Number Form to Excel Serial Date Number Form.
%
%   DateNumber = m2xdate(MATLABDateNumber, Convention)
%
%   Summary: This function converts serial date numbers from the MATLAB
%            serial date number format to the Excel serial date number
%            format.
%
%   Inputs: MATLABDateNumber - Array of serial date numbers in MATLAB
%              serial date number form.
%
%           Convention - Scalar or an array of flags indicating which Excel
%              serial date number convention should be used when converting
%              from MATLAB serial date numbers; possible values are:
%                 a) 0 : 1900 date system in which a serial date number of
%                        one corresponds to the date 1-Jan-1900 {default}.
%                 b) 1 : 1904 date system in which a serial date number of
%                        zero corresponds to the date 1-Jan-1904.
%              Convention must be either a scalar or else must be the same
%                 size as MATLABDateNumber.
%
%   Outputs: Array of serial date numbers in Excel serial date number form.
%
% 
%   Example: StartDate = 729706
%            Convention = 0;
%
%            EndDate = m2xdate(StartDate, Convention);
%
%            returns:
%
%            EndDate = 35746
%
%   See also X2MDATE.

%   Copyright 1995-2013 The MathWorks, Inc.

% Check for empty dates
if isempty(MATLABDateNumber)
    DateNumber = MATLABDateNumber;
    return   
end

% Convert date strings to serial date numbers if necessary
if any(ischar(MATLABDateNumber(:)))
     MATLABDateNumber = datenum(MATLABDateNumber);
end

% Check the number of arguments in and set defaults
if nargin < 2
     Convention = zeros(size(MATLABDateNumber));
end

% Make sure input date numbers are positive
if any(MATLABDateNumber(:) <= 0)
     error(message('finance:m2xdate:inputsMustBePositive'))
end

% Do any needed scalar expansion on the convention flag and parse
if isscalar(Convention)
    Convention = Convention * ones(size(MATLABDateNumber));
elseif ~isequal(size(Convention),size(MATLABDateNumber))
    error(message('finance:m2xdate:invalidConventionSize'))
end

invalidConvention = (Convention ~= 0 & Convention ~= 1);
if any(invalidConvention(:))
     error(message('finance:m2xdate:invalidConvention'))
end

% Initialize all as NaN.  NaN dates should fall through as NaNs.
origSize = size(MATLABDateNumber);
DateNumber = nan(origSize);

% Set conversion factor for both (1900 & 1904) date systems
X2MATLAB1900 = 693961;
X2MATLAB1904 = 695422;

% Convert to the Excel serial date number
actual1900Idx = (Convention == 0 & MATLABDateNumber < 694021);
if any(actual1900Idx(:))
     DateNumber(actual1900Idx) = MATLABDateNumber(actual1900Idx) - X2MATLAB1900;
end

% Excel erroneously believes 1900 was a leap year, so after February 28,
% 1900, we adjust to account for this.
corrected1900Idx = (Convention == 0 & MATLABDateNumber >= 694021);
if any(corrected1900Idx(:))
    DateNumber(corrected1900Idx) = MATLABDateNumber(corrected1900Idx) - X2MATLAB1900 + 1;
end

% Using the 1904 convention there is no issue with the incorrect leap year.
X1904Ind = (Convention == 1);
if any(X1904Ind(:))
     DateNumber(X1904Ind) = MATLABDateNumber(X1904Ind) - X2MATLAB1904;
end

