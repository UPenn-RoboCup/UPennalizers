function [ local_rot ] = abs2local_rot( abs_rot )
%UNTITLED Torso is root
%   Detailed explanation goes here
local_rot = abs_rot;
for j=2:size(abs_rot,3)
    % R_abs = R_local * R_root
    % R_abs * R_root' = R_local * R_root * R_root'
    % R_abs * R_root' = R_local
    R_root = abs_rot(:,:,j-1);
    local_rot(:,:,j) = abs_rot(:,:,j) * R_root';
    %local_rot(:,:,j) = abs_rot(:,:,j)' * R_root;
    %local_rot(:,:,j) = R_root * abs_rot(:,:,j)';
    %local_rot(:,:,j) = R_root' * abs_rot(:,:,j);
    if( find(j==[5 11 17 21]) ) % Waist is its root
        R_root = abs_rot(:,:,4);
        local_rot(:,:,j) = abs_rot(:,:,j) * R_root';
        %local_rot(:,:,j) = abs_rot(:,:,j)' * R_root;
        %local_rot(:,:,j) = R_root * abs_rot(:,:,j)';
        %local_rot(:,:,j) = R_root' * abs_rot(:,:,j);
    end
end

end

