function normals = computeNormals(vertices)
normals = normalize(vertices(:,1:end-1) - vertices(:,2:end), 'norm');
normals = [normals(2,:); -normals(1,:)];
end