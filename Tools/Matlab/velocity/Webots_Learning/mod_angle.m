function [ th ] = mod_angle( th )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    th = mod(th, (2*pi) );
    th(th >= pi) = th(th >= pi) - 2*pi;
end

