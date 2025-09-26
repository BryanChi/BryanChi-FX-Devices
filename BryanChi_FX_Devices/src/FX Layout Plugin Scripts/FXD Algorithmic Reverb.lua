-- @noindex

local FX_Idx = PluginScript.FX_Idx
local FxGUID = PluginScript.Guid
local fx = FX[FxGUID]

fx.CustomTitle = 'Algorithmic Reverb'
fx.TitleWidth = 120
fx.Width = 620
fx.BgClr = 0x111111ff
fx.Dont_Allow_Add_Prm = true

-- JSFX slider param indices (0-based)
local P = {
  mat = 0,
  room_len = 1,
  room_wid = 2,
  room_hgt = 3,
  mic_x = 4,
  mic_y = 5,
  mic_z = 6,
  src_x = 7,
  src_y = 8,
  src_z = 9,
  mod_amt = 10,
  mix = 11,
  density = 12,
  dry = 13,
  mic_facing_deg = 14,
}

-- Room dimension ranges (match JSFX sliders)
local LEN_MIN, LEN_MAX = 2, 50
local WID_MIN, WID_MAX = 2, 50
local HGT_MIN, HGT_MAX = 2, 20

local function val_to_norm(v, vmin, vmax)
  return (v - vmin) / (vmax - vmin)
end
local function norm_to_val(n, vmin, vmax)
  return vmin + n * (vmax - vmin)
end

local function get_param(idx)
  return r.TrackFX_GetParamNormalized(LT_Track, FX_Idx, idx)
end
local function set_param(idx, norm)
  r.TrackFX_SetParamNormalized(LT_Track, FX_Idx, idx, math.min(1, math.max(0, norm)))
end

-- UI sizing
local VIEW_W = 300
local VIEW_H = 160
local SIDE_W = 140

-- 2-view helpers: map room coords to front XY and side YZ panels
local function map_xy(x, y, Lx, Ly, L, T, W, H)
  local sx = L + (x / math.max(0.0001, Lx)) * W
  local sy = T + H - (y / math.max(0.0001, Ly)) * H
  return sx, sy
end
local function map_yz(y, z, Ly, Lz, L, T, W, H)
  local sx = L + (y / math.max(0.0001, Ly)) * W
  local sy = T + H - (z / math.max(0.0001, Lz)) * H
  return sx, sy
end

-- Hit tests and dragging state
fx.__arv = fx.__arv or {}
local st = fx.__arv

-- Knobs will use AddKnob from Layout Editor functions.lua

-- Particle system (module-level, simple)
fx.__arv_particles = fx.__arv_particles or {list={}, last_stamp=0, max=500, speed=10}
local Psys = fx.__arv_particles

local function col(r,g,b,a)
  return im.ColorConvertDouble4ToU32(r,g,b,a or 1)
end

local function rand_unit_vec()
  local x = (math.random()*2-1)
  local y = (math.random()*2-1)
  local z = (math.random()*2-1)
  local len = math.sqrt(x*x+y*y+z*z)+1e-9
  return x/len, y/len, z/len
end

local function spawn_particles(num, color, origin, speed, baseA, rt60)
  for i=1,num do
    if #Psys.list >= (Psys.max or 500) then 
      local oldest = Psys.list[1]
      if oldest then 
        oldest.decay = (oldest.decay or 1) * 8
        oldest.a = (oldest.a or 0.8) * 0.4
        oldest.killing = true
      end
    end
    local ux,uy,uz = rand_unit_vec()
    -- slight upward bias so it feels energetic
    uy = uy + 0.3
    local p = {
      x = origin.x, y = origin.y, z = origin.z,
      vx = ux * (speed or 1) * (Psys.speed or 1),
      vy = uy * (speed or 1) * (Psys.speed or 1),
      vz = uz * (speed or 1) * (Psys.speed or 1),
      life = 1.0, clr = color, a = baseA or 0.9,
      decay = (1 / math.max(0.2, math.min(10.0, rt60 or 1.5))) * (0.8 + 0.4*math.random()),
      path = {}, phase = math.random()*6.28318, t = 0, sample_accum = 0,
    }
    table.insert(Psys.list, p)
  end
end

local function update_particles(dt, Lx, Ly, Lz, alpha, rt60)
  local k = 0.998 -- even less drag
  local bounce = 0.75 * (1 - alpha) + 0.35 -- stronger bounces on reflective rooms
  local tau = math.max(0.2, math.min(10.0, rt60 or 1.5))
  for i=#Psys.list,1,-1 do
    local p = Psys.list[i]
    -- no attraction to origin; only gravity and wall bounces
    local dts = dt * (Psys.speed or 1)
    p.vy = p.vy - 1.2*dts
    p.x = p.x + p.vx*dts
    p.y = p.y + p.vy*dts
    p.z = p.z + p.vz*dts
    p.vx = p.vx*k; p.vy = p.vy*k; p.vz = p.vz*k
    -- collide with room bounds
    if p.x < 0 then p.x=0; p.vx = -p.vx*bounce end
    if p.x > Lx then p.x=Lx; p.vx = -p.vx*bounce end
    if p.y < 0 then p.y=0; p.vy = -p.vy*bounce end
    if p.y > Ly then p.y=Ly; p.vy = -p.vy*bounce end
    if p.z < 0 then p.z=0; p.vz = -p.vz*bounce end
    if p.z > Lz then p.z=Lz; p.vz = -p.vz*bounce end
    -- record path for wave rendering
    local sample_dt = 0.02
    p.t = p.t + dts
    p.sample_accum = (p.sample_accum or 0) + dts
    if p.sample_accum >= sample_dt then
      p.sample_accum = 0
      local node = {x=p.x, y=p.y, z=p.z}
      table.insert(p.path, node)
      if #p.path > 12 then table.remove(p.path,1) end
    end
    -- life decays based on per-particle decay tied to RT60
    p.life = p.life - dts * (p.decay or (1/(tau*1.2)))
    if p.life <= 0 then table.remove(Psys.list, i) end
  end
end

local function point_in_rect(x,y, r)
  return x > r.x and x < r.x+r.w and y > r.y and y < r.y+r.h
end

local function render_particles(rot_project_fn, WDL, edge_lines, alpha_scale)
  for _,p in ipairs(Psys.list) do
    -- Wave-like soft trail using layered ImGui path strokes
    local a = math.max(0, math.min(1, (p.a or 0.8) * (p.life or 1) * (alpha_scale or 1)))
    local R = ((p.clr>>0) & 0xff)/255.0
    local G = ((p.clr>>8) & 0xff)/255.0
    local B = ((p.clr>>16)& 0xff)/255.0
    local function stroke(alpha, thick)
      im.DrawList_PathClear(WDL)
      local prev_sx, prev_sy
      for j=1,#p.path do
        local px,py,pz = rot_project_fn(p.path[j].x, p.path[j].y, p.path[j].z)
        if prev_sx then
          local dx,dy = px-prev_sx, py-prev_sy
          local len = math.sqrt(dx*dx+dy*dy)+1e-9
          local nx,ny = -dy/len, dx/len
          local amp = 5 * (p.life or 1)
          local off = math.sin(p.phase + p.t*10 + j*0.6) * amp
          -- prevent offset from pushing outside box silhouette by capping to nearest edge distance
          if edge_lines and #edge_lines>0 then
            local mind = 1e9
            for _,e in ipairs(edge_lines) do
              local x1,y1,x2,y2 = e[1],e[2],e[3],e[4]
              local ex,ey = x2-x1, y2-y1
              local wx,wy = px - x1, py - y1
              local c1 = ex*wx + ey*wy
              local c2 = ex*ex + ey*ey + 1e-9
              local t = math.max(0, math.min(1, c1/c2))
              local hx,hy = x1 + ex*t, y1 + ey*t
              local ddx, ddy = px-hx, py-hy
              local d = math.sqrt(ddx*ddx + ddy*ddy)
              if d < mind then mind = d end
            end
            local cap = math.max(0, (mind or 0) - 2)
            if off >  cap then off =  cap end
            if off < -cap then off = -cap end
          end
          px = px + nx*off
          py = py + ny*off
        end
        im.DrawList_PathLineTo(WDL, px, py)
        prev_sx, prev_sy = px, py
      end
      im.DrawList_PathStroke(WDL, col(R,G,B,alpha*a), 0, thick)
    end
    if #p.path >= 2 then
      stroke(0.08, 9)  -- outer glow
      stroke(0.16, 6)  -- softer halo
      stroke(0.32, 2.6) -- core
    else
      -- draw short segment instead of a dot
      im.DrawList_PathClear(WDL)
      local x1,y1 = rot_project_fn(p.x, p.y, p.z)
      local x0,y0 = rot_project_fn(p.x - p.vx*0.02, p.y - p.vy*0.02, p.z - p.vz*0.02)
      im.DrawList_PathLineTo(WDL, x0, y0)
      im.DrawList_PathLineTo(WDL, x1, y1)
      im.DrawList_PathStroke(WDL, col(R,G,B,0.32*a), 0, 2.0)
    end
  end
end

-- Main render
do
  im.SetCursorPos(ctx, 0, 20)
  if im.BeginChild(ctx, '##ARV_VIEW' .. FxGUID, VIEW_W + SIDE_W + 40, VIEW_H + 40, nil) then
    -- Attach gmem for telemetry
    r.gmem_attach('FXD_ARV')
    local stamp = r.gmem_read(0)
    local e_in  = r.gmem_read(1)
    local e_er  = r.gmem_read(2)
    local e_lat = r.gmem_read(3)
    local js_len= r.gmem_read(4)
    local js_wid= r.gmem_read(5)
    local js_hgt= r.gmem_read(6)
    local s_nx  = r.gmem_read(7); local s_ny = r.gmem_read(8); local s_nz = r.gmem_read(9)
    local m_nx  = r.gmem_read(10);local m_ny = r.gmem_read(11);local m_nz = r.gmem_read(12)
    local rt60  = r.gmem_read(13)

    local WDL = im.GetWindowDrawList(ctx)
    local L, T = im.GetItemRectMin(ctx)
    local viewL, viewT = L + 8, T + 8
    local viewW, viewH = VIEW_W, VIEW_H
    local sideL = viewL + viewW + 16

    -- Read current params
    -- Remap JSFX dimensions for display only per request:
    --  Length (JSFX) -> Depth (Z), Width (JSFX) -> Width (X), Height (JSFX) -> Height (Y)
    local dispW = norm_to_val(get_param(P.room_wid), WID_MIN, WID_MAX) -- X from Width
    local dispH = norm_to_val(get_param(P.room_hgt), HGT_MIN, HGT_MAX) -- Y from Height
    local dispD = norm_to_val(get_param(P.room_len), LEN_MIN, LEN_MAX) -- Z from Length
    local Lx, Ly, Lz = dispW, dispH, dispD
    local mic = {
      x = get_param(P.mic_x) * Lx,
      y = get_param(P.mic_y) * Ly,
      z = get_param(P.mic_z) * Lz,
    }
    local src = {
      x = get_param(P.src_x) * Lx,
      y = get_param(P.src_y) * Ly,
      z = get_param(P.src_z) * Lz,
    }

    -- Single 3D canvas
    im.DrawList_AddRectFilled(WDL, viewL, viewT, viewL + viewW, viewT + viewH, 0x202020ff)
    im.DrawList_AddRect(WDL, viewL, viewT, viewL + viewW, viewT + viewH, 0x404040ff)

    -- View rotation state (defaults requested by user; still user-tweakable)
    if not st.init_view then
      st.yaw = math.rad(8)
      st.pitch = math.rad(20)
      st.roll = math.rad(206)
      st.init_view = true
    end
    st.view = 'free'
    st.t_yaw, st.t_pitch, st.ease = nil, nil, nil
    local maxDim = math.max(Lx, Ly, Lz)
    local scale = 0.60 * math.min(viewW, viewH) / math.max(0.0001, maxDim)
    -- Shape presentation tweaks
    local shapeScale = scale * 2.0
    local shapeOffsetX = -20

    -- Compatibility helpers
    local function atan2_compat(y, x)
      if math.atan2 then return math.atan2(y, x) end
      return math.atan(y, x)
    end
    local function rad2deg(a)
      return (a or 0) * (180 / math.pi)
    end

    -- View controls: yaw, pitch, and roll gizmos in the top-right corner
    do
      local areaW, areaH = 92, 36
      local ax, ay = viewL + viewW - areaW - 8, viewT + 8
      -- background
      im.DrawList_AddRectFilled(WDL, ax, ay, ax+areaW, ay+areaH, 0x00000055, 4)
      im.DrawList_AddRect(WDL, ax, ay, ax+areaW, ay+areaH, 0xFFFFFF33, 4)

      -- Yaw slider (left-right)
      local yawX, yawY, yawW, yawH = ax + 6, ay + 6, 46, 8
      im.DrawList_AddRectFilled(WDL, yawX, yawY, yawX+yawW, yawY+yawH, 0x404040aa, 2)
      local yawNorm = ( (st.yaw % (math.pi*2)) / (math.pi*2) )
      local knobX = yawX + yawNorm * yawW
      im.DrawList_AddCircleFilled(WDL, knobX, yawY + yawH/2, 4, 0xE0E0E0ff)
      im.SetCursorScreenPos(ctx, yawX, yawY)
      im.InvisibleButton(ctx, '##yaw'..FxGUID, yawW, yawH)
      if im.IsItemHovered(ctx) then FX_DeviceWindow_NoScroll = im.WindowFlags_NoScrollWithMouse end
      if im.IsItemActive(ctx) and IsLBtnHeld then
        local mx,_ = im.GetMousePos(ctx)
        local t = math.min(1, math.max(0, (mx - yawX) / yawW))
        st.yaw = t * (math.pi*2)
      end
      if im.IsItemHovered(ctx) then
        im.BeginTooltip(ctx)
        im.Text(ctx, string.format('Yaw: %.1f°', (rad2deg(st.yaw)) % 360))
        im.EndTooltip(ctx)
      end
      im.DrawList_AddText(WDL, yawX-2, yawY-12, 0xA0A0A0ff, 'Yaw')

      -- Pitch slider (up-down)
      local pX, pY, pW, pH = ax + 6, ay + 20, 46, 8
      im.DrawList_AddRectFilled(WDL, pX, pY, pX+pW, pY+pH, 0x404040aa, 2)
      local minP, maxP = -math.pi*0.49, math.pi*0.49
      local pNorm = (st.pitch - minP) / (maxP - minP)
      local pkx = pX + math.min(1, math.max(0, pNorm)) * pW
      im.DrawList_AddCircleFilled(WDL, pkx, pY + pH/2, 4, 0xE0E0E0ff)
      im.SetCursorScreenPos(ctx, pX, pY)
      im.InvisibleButton(ctx, '##pitch'..FxGUID, pW, pH)
      if im.IsItemHovered(ctx) then FX_DeviceWindow_NoScroll = im.WindowFlags_NoScrollWithMouse end
      if im.IsItemActive(ctx) and IsLBtnHeld then
        local mx,_ = im.GetMousePos(ctx)
        local t = math.min(1, math.max(0, (mx - pX) / pW))
        st.pitch = minP + t * (maxP - minP)
      end
      if im.IsItemHovered(ctx) then
        im.BeginTooltip(ctx)
        im.Text(ctx, string.format('Pitch: %.1f°', rad2deg(st.pitch)))
        im.EndTooltip(ctx)
      end
      im.DrawList_AddText(WDL, pX-2, pY-12, 0xA0A0A0ff, 'Pitch')

      -- Roll knob (right)
      local rz = 10
      local cx, cy = ax + areaW - rz - 8, ay + areaH/2
      im.DrawList_AddCircle(WDL, cx, cy, rz, 0xA0A0A0ff)
      local pr = rz - 2
      local px = cx + math.cos(st.roll) * pr
      local py = cy + math.sin(st.roll) * pr
      im.DrawList_AddLine(WDL, cx, cy, px, py, 0xD0D0D0ff, 2)
      im.SetCursorScreenPos(ctx, cx - rz, cy - rz)
      im.InvisibleButton(ctx, '##roll'..FxGUID, rz*2, rz*2)
      if im.IsItemHovered(ctx) then FX_DeviceWindow_NoScroll = im.WindowFlags_NoScrollWithMouse end
      if im.IsItemActive(ctx) and IsLBtnHeld then
        local mx, my = im.GetMousePos(ctx)
        st.roll = atan2_compat(my - cy, mx - cx)
      end
      if im.IsItemHovered(ctx) then
        im.BeginTooltip(ctx)
        im.Text(ctx, string.format('Roll: %.1f°', (rad2deg(st.roll)) % 360))
        im.EndTooltip(ctx)
      end
      im.DrawList_AddText(WDL, cx-12, ay-4, 0xA0A0A0ff, 'Roll')
    end

    -- easing disabled due to locked view

    -- Projection helper
    local function rot_project(x, y, z)
      local cx, cy, cz = Lx*0.5, Ly*0.5, Lz*0.5
      local X, Y, Z = x - cx, y - cy, z - cz
      -- Blended face projection during easing between orthographic faces
      if st.ease then
        local function face_proj(face)
          if face=='front' then return X, Y, Z
          elseif face=='side' then return Z, Y, X
          elseif face=='top' then return X, Z, Y end
          return X, Y, Z
        end
        local ax,ay,ad = face_proj(st.ease.from)
        local bx,by,bd = face_proj(st.ease.to)
        local t = st.ease.t or 0
        local px = ax*(1-t) + bx*t
        local py = ay*(1-t) + by*t
        local pz = ad*(1-t) + bd*t
        local sx = viewL + viewW*0.5 + px * scale
        local sy = viewT + viewH*0.60 - py * scale
        return sx, sy, pz
      end
      -- Locked to fixed yaw/pitch with additional roll around Y axis
      local c, s = math.cos(st.yaw), math.sin(st.yaw)
      local X1 = X*c - Y*s
      local Y1 = X*s + Y*c
      local Z1 = Z
      local cp, sp = math.cos(st.pitch), math.sin(st.pitch)
      local Y2 = Y1*cp - Z1*sp
      local Z2 = Y1*sp + Z1*cp
      local cr, sr = math.cos(st.roll or 0), math.sin(st.roll or 0)
      local X3 = X1*cr + Z2*sr
      local Z3 = -X1*sr + Z2*cr
      local sx = viewL + viewW*0.5 + X3 * scale
      local sy = viewT + viewH*0.60 - Y2 * scale
      return sx, sy, Z3
    end

    -- Projection helper for the shape (double size and left offset)
    local function rot_project_shape(x, y, z)
      local cx, cy, cz = Lx*0.5, Ly*0.5, Lz*0.5
      local X, Y, Z = x - cx, y - cy, z - cz
      local c, s = math.cos(st.yaw), math.sin(st.yaw)
      local X1 = X*c - Y*s
      local Y1 = X*s + Y*c
      local Z1 = Z
      local cp, sp = math.cos(st.pitch), math.sin(st.pitch)
      local Y2 = Y1*cp - Z1*sp
      local Z2 = Y1*sp + Z1*cp
      local cr, sr = math.cos(st.roll or 0), math.sin(st.roll or 0)
      local X3 = X1*cr + Z2*sr
      local Z3 = -X1*sr + Z2*cr
      local sx = viewL + viewW*0.5 + X3 * shapeScale + shapeOffsetX
      local sy = viewT + viewH*0.60 - Y2 * shapeScale
      return sx, sy, Z3
    end

    -- Project room corners and draw wireframe with depth shading
    local pts = {
      {0,0,0}, {Lx,0,0}, {0,Ly,0}, {Lx,Ly,0},
      {0,0,Lz}, {Lx,0,Lz}, {0,Ly,Lz}, {Lx,Ly,Lz}
    }
    local proj, minZ, maxZ = {}, nil, nil
    for i=1,#pts do
      local sx, sy, z = rot_project_shape(pts[i][1], pts[i][2], pts[i][3])
      proj[i] = {sx, sy, z}
      minZ = (minZ and math.min(minZ, z)) or z
      maxZ = (maxZ and math.max(maxZ, z)) or z
    end
    -- perspective guide lines from room center to corners
    local cxp, cyp = rot_project_shape(Lx*0.5, Ly*0.5, Lz*0.5)
    for i=1,#proj do
      im.DrawList_AddLine(WDL, cxp, cyp, proj[i][1], proj[i][2], 0x303030ff, 1)
    end
    local function shade(z)
      local n = (z - minZ) / math.max(1e-9, (maxZ - minZ))
      local b = 0.55 + (1 - n) * 0.35
      local v = math.floor(255*b)
      return (v<<24) + (v<<16) + (v<<8) + 0xff
    end
    -- rotate vector into camera space (no translation)
    local function rotate_vec(x,y,z)
      local c, s = math.cos(st.yaw), math.sin(st.yaw)
      local X1 = x*c - y*s
      local Y1 = x*s + y*c
      local Z1 = z
      local cp, sp = math.cos(st.pitch), math.sin(st.pitch)
      local Y2 = Y1*cp - Z1*sp
      local Z2 = Y1*sp + Z1*cp
      local cr, sr = math.cos(st.roll or 0), math.sin(st.roll or 0)
      local X3 = X1*cr + Z2*sr
      local Z3 = -X1*sr + Z2*cr
      return X3, Y2, Z3
    end
    -- face normals in camera space
    local nxX,nxY,nxZ = rotate_vec(-1,0,0)
    local pxX,pxY,pxZ = rotate_vec( 1,0,0)
    local nyX,nyY,nyZ = rotate_vec(0,-1,0)
    local pyX,pyY,pyZ = rotate_vec(0, 1,0)
    local nzX,nzY,nzZ = rotate_vec(0,0,-1)
    local pzX,pzY,pzZ = rotate_vec(0,0, 1)
    local function face_front(zc)
      return zc < 0 -- if wrong polarity, flip to zc > 0
    end
    -- subtle face shading
    local function shade_face(pidx, alpha)
      im.DrawList_PathClear(WDL)
      for k=1,4 do
        local pt = proj[pidx[k]]
        im.DrawList_PathLineTo(WDL, pt[1], pt[2])
      end
      im.DrawList_PathFillConvex(WDL, alpha)
    end
    -- faces defined by point indices and normals
    local faces = {
      {pts={1,2,4,3}, z= nzZ}, -- bottom (z=0)
      {pts={5,6,8,7}, z= pzZ}, -- top (z=Lz)
      {pts={1,2,6,5}, z= nyZ}, -- y=0
      {pts={3,4,8,7}, z= pyZ}, -- y=Ly
      {pts={1,3,7,5}, z= nxZ}, -- x=0
      {pts={2,4,8,6}, z= pxZ}, -- x=Lx
    }
    -- draw back faces first, then front faces (very subtle)
    for _,f in ipairs(faces) do
      if not face_front(f.z) then shade_face(f.pts, 0x00000018) end
    end
    for _,f in ipairs(faces) do
      if face_front(f.z) then shade_face(f.pts, 0xFFFFFF12) end
    end
    -- dotted line helper
    local function draw_dotted(ax,ay,bx,by, clr)
      local dx,dy = bx-ax, by-ay
      local dist = math.sqrt(dx*dx + dy*dy) + 1e-9
      local seg, gap = 6, 4
      local ux,uy = dx/dist, dy/dist
      local n = math.floor(dist/(seg+gap))
      local sx,sy = ax,ay
      for i=1,n do
        local ex = sx + ux*seg
        local ey = sy + uy*seg
        im.DrawList_AddLine(WDL, sx, sy, ex, ey, clr, 1.6)
        sx = ex + ux*gap
        sy = ey + uy*gap
      end
      if sx < bx or sy < by then
        im.DrawList_AddLine(WDL, sx, sy, bx, by, clr, 1.6)
      end
    end
    -- edges with face adjacency for hidden/visible style
    local edges = {
      {1,2, nyZ, nzZ}, {1,3, nxZ, nzZ}, {2,4, pxZ, nzZ}, {3,4, pyZ, nzZ},
      {5,6, nyZ, pzZ}, {5,7, nxZ, pzZ}, {6,8, pxZ, pzZ}, {7,8, pyZ, pzZ},
      {1,5, nxZ, nyZ}, {2,6, pxZ, nyZ}, {3,7, nxZ, pyZ}, {4,8, pxZ, pyZ},
    }
    -- groups for dimension hover (by axis)
    local groupX = { ['1-2']=true, ['3-4']=true, ['5-6']=true, ['7-8']=true }
    local groupY = { ['1-3']=true, ['2-4']=true, ['5-7']=true, ['6-8']=true }
    local groupZ = { ['1-5']=true, ['2-6']=true, ['3-7']=true, ['4-8']=true }
    local function keypair(a,b) if a<b then return a..'-'..b else return b..'-'..a end end
    local function near_seg_edge(px,py,qx,qy,th, mx, my)
      local vx,vy = qx-px, qy-py
      local wx,wy = mx - px, my - py
      local c1 = vx*wx + vy*wy
      local c2 = vx*vx + vy*vy + 1e-9
      local t = math.max(0, math.min(1, c1/c2))
      local hx,hy = px + t*vx, py + t*vy
      local dx,dy = mx-hx, my-hy
      return (dx*dx + dy*dy) <= th*th
    end
    -- Screen hover for edges (skip if hovering node)
    local hover_dim
    if not overMicPt and not overSrcPt and not st.axisActive and not st.dimActive and not st.dragging and not st.gizmoHovering then
      local MsX2, MsY2 = im.GetMousePos(ctx)
      for _,e in ipairs(edges) do
        local a,b = proj[e[1]], proj[e[2]]
        if near_seg_edge(a[1],a[2], b[1],b[2], 8, MsX2, MsY2) then
          local k = keypair(e[1], e[2])
          if groupX[k] then hover_dim='x' elseif groupY[k] then hover_dim='y' elseif groupZ[k] then hover_dim='z' end
          break
        end
      end
      if hover_dim then
        if hover_dim=='x' then im.SetMouseCursor(ctx, im.MouseCursor_ResizeEW) else im.SetMouseCursor(ctx, im.MouseCursor_ResizeNS) end
        if IsLBtnClicked then st.drag_dim3d = hover_dim; st.dimActive = true end
      end
    end
    -- If user is dragging a node, cancel any side-drag in progress
    if st.dragging and st.drag_dim3d then st.drag_dim3d=nil; st.dimActive=false end
    if st.drag_dim3d then
      local dx,dy = im.GetMouseDelta(ctx)
      if st.drag_dim3d=='x' then
        Lx = math.min(WID_MAX, math.max(WID_MIN, Lx + (dx/shapeScale)))
        set_param(P.room_wid, val_to_norm(Lx, WID_MIN, WID_MAX))
      elseif st.drag_dim3d=='y' then
        Ly = math.min(HGT_MAX, math.max(HGT_MIN, Ly + (-dy/shapeScale)))
        set_param(P.room_hgt, val_to_norm(Ly, HGT_MIN, HGT_MAX))
      elseif st.drag_dim3d=='z' then
        Lz = math.min(LEN_MAX, math.max(LEN_MIN, Lz + (-dy/shapeScale)))
        set_param(P.room_len, val_to_norm(Lz, LEN_MIN, LEN_MAX))
      end
      if not IsLBtnHeld then st.drag_dim3d = nil; st.dimActive = false end
    end
    for _,e in ipairs(edges) do
      local a,b = proj[e[1]], proj[e[2]]
      local clr = shade((a[3]+b[3])*0.5)
      local frontA = face_front(e[3])
      local frontB = face_front(e[4])
      local k = keypair(e[1], e[2])
      local thick = 1.8
      if hover_dim then
        if (hover_dim=='x' and groupX[k]) or (hover_dim=='y' and groupY[k]) or (hover_dim=='z' and groupZ[k]) then thick = 3.2 end
      end
      if frontA or frontB then
        im.DrawList_AddLine(WDL, a[1],a[2], b[1],b[2], clr, thick)
      else
        local dclr = (thick>2.5 and 0xA0A0A0aa or 0x808080aa)
        draw_dotted(a[1],a[2], b[1],b[2], dclr)
      end
    end
    local edge_lines = {
      {proj[1][1],proj[1][2], proj[2][1],proj[2][2]}, {proj[1][1],proj[1][2], proj[3][1],proj[3][2]},
      {proj[2][1],proj[2][2], proj[4][1],proj[4][2]}, {proj[3][1],proj[3][2], proj[4][1],proj[4][2]},
      {proj[5][1],proj[5][2], proj[6][1],proj[6][2]}, {proj[5][1],proj[5][2], proj[7][1],proj[7][2]},
      {proj[6][1],proj[6][2], proj[8][1],proj[8][2]}, {proj[7][1],proj[7][2], proj[8][1],proj[8][2]},
      {proj[1][1],proj[1][2], proj[5][1],proj[5][2]}, {proj[2][1],proj[2][2], proj[6][1],proj[6][2]},
      {proj[3][1],proj[3][2], proj[7][1],proj[7][2]}, {proj[4][1],proj[4][2], proj[8][1],proj[8][2]},
    }
    -- Floor grid that scales with room size and is contained within the view rectangle
    -- Fixed world grid: 1 meter spacing regardless of zoom
    local stepWorld = 10
    -- derive screen-space basis from FLOOR plane axes: world X (width) and world Z (depth) at y=0
    local ox,oy = rot_project(0,0,0)         -- origin at bottom corner (y=0)
    local x1,y1 = rot_project(1,0,0)         -- +X (width)
    local z1x,z1y = rot_project(0,0,1)       -- +Z (depth)
    local rvxX, rvxY = x1-ox, y1-oy          -- screen vector along X
    local rvyX, rvyY = z1x-ox, z1y-oy        -- screen vector along Z (depth)
    local lenX = math.sqrt(rvxX*rvxX + rvxY*rvxY) + 1e-9
    local lenY = math.sqrt(rvyX*rvyX + rvyY*rvyY) + 1e-9
    local uxX, uxY = rvxX/lenX, rvxY/lenX
    local uyX, uyY = rvyX/lenY, rvyY/lenY
    local stepXpx = lenX * stepWorld
    local stepYpx = lenY * stepWorld
    local diag = math.sqrt(viewW*viewW + viewH*viewH)
    local nX = math.min(300, math.ceil((diag*1.2) / math.max(4, stepXpx)) + 2)
    local nY = math.min(300, math.ceil((diag*1.2) / math.max(4, stepYpx)) + 2)
    
    -- Helper function to clip line to rectangle bounds
    local function clip_line_to_rect(x1, y1, x2, y2, rL, rT, rR, rB)
      -- Simple line clipping using parametric form
      local dx, dy = x2 - x1, y2 - y1
      local t_min, t_max = 0, 1
      
      -- Check each boundary
      local boundaries = {
        {rL - x1, dx},  -- left
        {x1 - rR, -dx}, -- right  
        {rT - y1, dy},  -- top
        {y1 - rB, -dy}  -- bottom
      }
      
      for _, bound in ipairs(boundaries) do
        local num, denom = bound[1], bound[2]
        if math.abs(denom) < 1e-9 then
          -- Line is parallel to boundary
          if num > 0 then return nil end -- outside boundary
        else
          local t = num / denom
          if denom > 0 then
            t_min = math.max(t_min, t)
          else
            t_max = math.min(t_max, t)
          end
          if t_min > t_max then return nil end -- no intersection
        end
      end
      
      local cx1 = x1 + t_min * dx
      local cy1 = y1 + t_min * dy
      local cx2 = x1 + t_max * dx
      local cy2 = y1 + t_max * dy
      return cx1, cy1, cx2, cy2
    end
    
    local half = diag
    -- lines parallel to Y (vary along X)
    for i=-nX,nX do
      local px = ox + uxX * (i * stepXpx)
      local py = oy + uxY * (i * stepXpx)
      local xA = px - uyX * half
      local yA = py - uyY * half
      local xB = px + uyX * half
      local yB = py + uyY * half
      local cx1, cy1, cx2, cy2 = clip_line_to_rect(xA, yA, xB, yB, viewL, viewT, viewL + viewW, viewT + viewH)
      if cx1 then
        im.DrawList_AddLine(WDL, cx1, cy1, cx2, cy2, 0x505050ff, 1)
      end
    end
    -- lines parallel to X (vary along Y)
    for j=-nY,nY do
      local px = ox + uyX * (j * stepYpx)
      local py = oy + uyY * (j * stepYpx)
      local xA = px - uxX * half
      local yA = py - uxY * half
      local xB = px + uxX * half
      local yB = py + uxY * half
      local cx1, cy1, cx2, cy2 = clip_line_to_rect(xA, yA, xB, yB, viewL, viewT, viewL + viewW, viewT + viewH)
      if cx1 then
        im.DrawList_AddLine(WDL, cx1, cy1, cx2, cy2, 0x505050ff, 1)
      end
    end

    -- Precompute mic/src projections for hover checks and update/spawn particles
    local mx,my,mz = rot_project_shape(mic.x,mic.y,mic.z)
    local sx,sy,sz = rot_project_shape(src.x,src.y,src.z)
    -- no easing commit (locked view)
    -- use current mouse position
    local MsX, MsY = im.GetMousePos(ctx)
    local function near_seg(px,py,qx,qy,th)
      local vx,vy = qx-px, qy-py
      local wx,wy = MsX - px, MsY - py
      local c1 = vx*wx + vy*wy
      local c2 = vx*vx + vy*vy + 1e-9
      local t = math.max(0, math.min(1, c1/c2))
      local hx,hy = px + t*vx, py + t*vy
      local dx,dy = MsX-hx, MsY-hy
      return (dx*dx + dy*dy) <= th*th
    end
    -- compute simple hover over dots for priority
    local function dist2(ax,ay,bx,by) local dx=ax-bx; local dy=ay-by; return dx*dx+dy*dy end
    local overMicPt = (dist2(MsX,MsY,mx,my) <= (12*12))
    local overSrcPt = (dist2(MsX,MsY,sx,sy) <= (12*12))
    -- dimension edge hover/drag disabled with locked perspective

    -- mic/src already projected above
    -- size/brightness with proximity (near brighter/larger)
    local function dot_style(depthZ)
      local n = (depthZ - minZ) / math.max(1e-9, (maxZ - minZ))
      local r = 6 + (1-n)*4
      local b = 0.65 + (1-n)*0.30
      local v = math.floor(255*b)
      local clr = (v<<24) + (v<<16) + (v<<8) + 0xff
      return r, clr
    end
    local Rmic, Cmic = dot_style(mz)
    local Rsrc, Csrc = dot_style(sz)
    im.DrawList_AddCircleFilled(WDL, mx, my, Rmic, Cmic)
    im.DrawList_AddText(WDL, mx + 8, my - 10, 0xC0FFFFFF, 'Mic')
    im.DrawList_AddCircleFilled(WDL, sx, sy, Rsrc, Csrc)
    im.DrawList_AddText(WDL, sx + 8, sy - 10, 0xC0FFFFFF, 'Src')

    -- Axis labels with double-sided arrows per face (renamed for swapped dims)
    local function draw_axis_arrows()
      local pad = 12
      if st.view=='front' then
        -- Y vertical on left
        local y1 = viewT + 16; local y2 = viewT + viewH - 8; local x = viewL + 10
        im.DrawList_AddLine(WDL, x, y1, x, y2, 0xA0A0A0ff, 2)
        im.DrawList_AddTriangleFilled(WDL, x, y1, x-5, y1+8, x+5, y1+8, 0xA0A0A0ff)
        im.DrawList_AddTriangleFilled(WDL, x, y2, x-5, y2-8, x+5, y2-8, 0xA0A0A0ff)
        im.DrawList_AddText(WDL, x+6, y1-6, 0xA0A0A0ff, 'H')
        -- X horizontal on bottom
        local x1 = viewL + 16; local x2 = viewL + viewW - 8; local y = viewT + viewH - 10
        im.DrawList_AddLine(WDL, x1, y, x2, y, 0xA0A0A0ff, 2)
        im.DrawList_AddTriangleFilled(WDL, x1, y, x1+8, y-5, x1+8, y+5, 0xA0A0A0ff)
        im.DrawList_AddTriangleFilled(WDL, x2, y, x2-8, y-5, x2-8, y+5, 0xA0A0A0ff)
        im.DrawList_AddText(WDL, x2-14, y-18, 0xA0A0A0ff, 'W')
      elseif st.view=='side' then
        -- Y vertical on left
        local y1 = viewT + 16; local y2 = viewT + viewH - 8; local x = viewL + 10
        im.DrawList_AddLine(WDL, x, y1, x, y2, 0xA0A0A0ff, 2)
        im.DrawList_AddTriangleFilled(WDL, x, y1, x-5, y1+8, x+5, y1+8, 0xA0A0A0ff)
        im.DrawList_AddTriangleFilled(WDL, x, y2, x-5, y2-8, x+5, y2-8, 0xA0A0A0ff)
        im.DrawList_AddText(WDL, x+6, y1-6, 0xA0A0A0ff, 'H')
        -- X (Length) horizontal on bottom (labeled X)
        local x1 = viewL + 16; local x2 = viewL + viewW - 8; local y = viewT + viewH - 10
        im.DrawList_AddLine(WDL, x1, y, x2, y, 0xA0A0A0ff, 2)
        im.DrawList_AddTriangleFilled(WDL, x1, y, x1+8, y-5, x1+8, y+5, 0xA0A0A0ff)
        im.DrawList_AddTriangleFilled(WDL, x2, y, x2-8, y-5, x2-8, y+5, 0xA0A0A0ff)
        im.DrawList_AddText(WDL, x2-14, y-18, 0xA0A0A0ff, 'W')
      elseif st.view=='top' then
        -- Y (Length) vertical on left (label Y)
        local y1 = viewT + 16; local y2 = viewT + viewH - 8; local x = viewL + 10
        im.DrawList_AddLine(WDL, x, y1, x, y2, 0xA0A0A0ff, 2)
        im.DrawList_AddTriangleFilled(WDL, x, y1, x-5, y1+8, x+5, y1+8, 0xA0A0A0ff)
        im.DrawList_AddTriangleFilled(WDL, x, y2, x-5, y2-8, x+5, y2-8, 0xA0A0A0ff)
        im.DrawList_AddText(WDL, x+6, y1-6, 0xA0A0A0ff, 'H')
        -- X (Width) horizontal on bottom (label X)
        local x1 = viewL + 16; local x2 = viewL + viewW - 8; local y = viewT + viewH - 10
        im.DrawList_AddLine(WDL, x1, y, x2, y, 0xA0A0A0ff, 2)
        im.DrawList_AddTriangleFilled(WDL, x1, y, x1+8, y-5, x1+8, y+5, 0xA0A0A0ff)
        im.DrawList_AddTriangleFilled(WDL, x2, y, x2-8, y-5, x2-8, y+5, 0xA0A0A0ff)
        im.DrawList_AddText(WDL, x2-14, y-18, 0xA0A0A0ff, 'W')
      end
    end
    draw_axis_arrows()

    -- Interaction: drag mic/src
    local MsX, MsY = im.GetMousePos(ctx)
    local function hit_circle(cx, cy, r)
      local dx, dy = MsX - cx, MsY - cy
      return (dx*dx + dy*dy) <= (r*r)
    end

    -- Convert screen move to room units for each view
    local function delta_front(dx, dy)  -- width (Ly) and height (Lz)
      local dW = (dx / math.max(1, viewW)) * Ly
      local dH = (-dy / math.max(1, viewH)) * Lz
      return dW, dH
    end
    local function delta_side(dx, dy)   -- length (Lx) and height (Lz)
      local dL = (dx / math.max(1, viewW)) * Lx
      local dH = (-dy / math.max(1, viewH)) * Lz
      return dL, dH
    end
    local function delta_top(dx, dy)    -- width (Ly) and length (Lx)
      local dW = (dx / math.max(1, viewW)) * Ly
      local dL = (-dy / math.max(1, viewH)) * Lx
      return dW, dL
    end

    if not st.dragging and not st.draggingAxis then
      if hit_circle(mx, my, Rmic + 3) and IsLBtnClicked then st.dragging = 'mic_xy' end
      if hit_circle(sx, sy, Rsrc + 3) and IsLBtnClicked then st.dragging = 'src_xy' end
    else
      if not IsLBtnHeld then st.dragging = nil else
        local dx, dy = im.GetMouseDelta(ctx)
        if st.dragging == 'mic_xy' then
          if st.view=='front' then
            -- Front: X=Width -> affects mic.x; Y=Height -> affects mic.y
            local dX = (dx / math.max(1, viewW)) * Lx;  mic.x = math.min(Lx, math.max(0, mic.x + dX))
            local dY = (-dy / math.max(1, viewH)) * Ly; mic.y = math.min(Ly, math.max(0, mic.y + dY))
          elseif st.view=='side' then
            -- Side: X=Length -> affects mic.z; Y=Height -> affects mic.y
            local dX = (dx / math.max(1, viewW)) * Lz;  mic.z = math.min(Lz, math.max(0, mic.z + dX))
            local dY = (-dy / math.max(1, viewH)) * Ly; mic.y = math.min(Ly, math.max(0, mic.y + dY))
          elseif st.view=='top' then
            -- Top: X=Width -> affects mic.x; Y=Length -> affects mic.z
            local dX = (dx / math.max(1, viewW)) * Lx;  mic.x = math.min(Lx, math.max(0, mic.x + dX))
            local dY = (-dy / math.max(1, viewH)) * Lz; mic.z = math.min(Lz, math.max(0, mic.z + dY))
          else -- free: vertical drag => JSFX Y, horizontal drag => JSFX Z (depth)
            local dZ = (dx / math.max(1, viewW)) * Lz;  mic.z = math.min(Lz, math.max(0, mic.z + dZ))
            local dY = (-dy / math.max(1, viewH)) * Ly; mic.y = math.min(Ly, math.max(0, mic.y + dY))
          end
          set_param(P.mic_x, mic.x / Lx)
          set_param(P.mic_y, mic.y / Ly)
          set_param(P.mic_z, mic.z / Lz)
        elseif st.dragging == 'src_xy' then
          if st.view=='front' then
            local dX = (dx / math.max(1, viewW)) * Lx;  src.x = math.min(Lx, math.max(0, src.x + dX))
            local dY = (-dy / math.max(1, viewH)) * Ly; src.y = math.min(Ly, math.max(0, src.y + dY))
          elseif st.view=='side' then
            local dX = (dx / math.max(1, viewW)) * Lz;  src.z = math.min(Lz, math.max(0, src.z + dX))
            local dY = (-dy / math.max(1, viewH)) * Ly; src.y = math.min(Ly, math.max(0, src.y + dY))
          elseif st.view=='top' then
            local dX = (dx / math.max(1, viewW)) * Lx;  src.x = math.min(Lx, math.max(0, src.x + dX))
            local dY = (-dy / math.max(1, viewH)) * Lz; src.z = math.min(Lz, math.max(0, src.z + dY))
          else -- free: vertical drag => JSFX Y, horizontal drag => JSFX Z (depth)
            local dZ = (dx / math.max(1, viewW)) * Lz;  src.z = math.min(Lz, math.max(0, src.z + dZ))
            local dY = (-dy / math.max(1, viewH)) * Ly; src.y = math.min(Ly, math.max(0, src.y + dY))
          end
          set_param(P.src_x, src.x / Lx)
          set_param(P.src_y, src.y / Ly)
          set_param(P.src_z, src.z / Lz)
        end
      end
    end
    -- No edge resizing in orbit mode

    -- Particle spawning based on gmem energies
    do
      local new_stamp = r.gmem_read(0)
      local e_in  = math.max(0, r.gmem_read(1) or 0)
      local e_er  = math.max(0, r.gmem_read(2) or 0)
      local e_lat = math.max(0, r.gmem_read(3) or 0)
      local alpha = 1 - (get_param(P.mat) or 0) -- rough mapping
      -- spawn near source; colors: input=yellow, ER=cyan, late=magenta
      local src_origin = {x= src.x, y= src.y, z= src.z}
      local function amt(v) return math.min(80, math.floor(v * 400)) end
      local speed_in  = 7 + 16 * math.min(1, e_in)
      local speed_er  = 6 + 14 * math.min(1, e_er)
      local speed_lat = 5 + 12 * math.min(1, e_lat)
      spawn_particles(amt(e_in),  0x70E0E0ff, src_origin, speed_in , 0.60, rt60)
      spawn_particles(amt(e_er),  0x70A0E0ff, src_origin, speed_er , 0.50, rt60)
      update_particles(1/60, Lx, Ly, Lz, alpha, rt60)
      -- render waves; nodes and text are drawn after particles ensuring front-most
      render_particles(rot_project_shape, WDL, edge_lines, 0.6)
    end

    -- Gizmo: appear on hover and allow axis-constrained dragging
    local function axis_screen_vec(px,py,pz, ax)
      -- UI axis mapping (using shape projection for exact alignment with drawn box):
      --  - 'x' -> world X (red = width)
      --  - 'y' -> world Y (green = vertical/height)
      --  - 'z' -> world Z (blue = depth)
      local ox,oy = rot_project_shape(px,py,pz)
      local nx,ny
      if ax=='x' then nx,ny = rot_project_shape(px+1,py,pz)
      elseif ax=='y' then nx,ny = rot_project_shape(px,py+1,pz)
      else nx,ny = rot_project_shape(px,py,pz+1)
      end
      return ox,oy, (nx-ox), (ny-oy)
    end
    local function draw_gizmo_for(target)
      -- prioritize gizmo over sides: only block if an edge drag is already active
      if st.dragging or st.drag_dim3d then return end
      local pos = target=='mic' and mic or src
      local cx,cy = rot_project_shape(pos.x,pos.y,pos.z)
      local axes = {
        {key='x', clr=0xFF4040ff},
        {key='y', clr=0x40FF40ff},
        {key='z', clr=0x4080D0ff},
      }
      local hovered
      for _,a in ipairs(axes) do
        local ox,oy,vx,vy = axis_screen_vec(pos.x,pos.y,pos.z, a.key)
        local unitLen = math.sqrt(vx*vx+vy*vy) + 1e-9
        local desired = 38
        local wx = (vx/unitLen)*desired
        local wy = (vy/unitLen)*desired
        local ex, ey = cx + wx, cy + wy
        im.DrawList_AddLine(WDL, cx, cy, ex, ey, a.clr, 2)
        im.DrawList_AddCircleFilled(WDL, ex, ey, 3, a.clr)
        if not st.axisActive and not st.dragging and near_seg(cx,cy, ex,ey, 6) then hovered = a.key; st.gizmoHovering=true; im.SetMouseCursor(ctx, im.MouseCursor_ResizeAll) end
      end
      if not st.axisActive and not st.dragging and hovered and IsLBtnClicked then st.draggingAxis = {t=target, axis=hovered}; st.axisActive=true end
    end
    -- gizmo stickiness: keep visible for a short timeout after unhover
    st.gizmoHovering = false
    st.gizmoTimer = st.gizmoTimer or 0
    local hoverAny = overMicPt or overSrcPt
    if hoverAny and not st.axisActive then
      st.gizmoTarget = overMicPt and 'mic' or 'src'
      st.gizmoTimer = r.time_precise()
    else
      if not st.draggingAxis and st.gizmoTimer > 0 then
        if (r.time_precise() - st.gizmoTimer) > 1.0 then -- 1s linger
          st.gizmoTarget = nil
        end
      end
    end
    if st.gizmoTarget then draw_gizmo_for(st.gizmoTarget) end

    if st.dragging and st.draggingAxis then st.draggingAxis=nil; st.axisActive=false end
    if st.draggingAxis then
      local target = st.draggingAxis.t
      local axis = st.draggingAxis.axis
      local pos = target=='mic' and mic or src
      local _,_,vx,vy = axis_screen_vec(pos.x,pos.y,pos.z, axis)
      local MsDX, MsDY = im.GetMouseDelta(ctx)
      local denom = (vx*vx + vy*vy) + 1e-9
      local along = (MsDX*vx + MsDY*vy) / denom
      if axis=='x' then pos.x = math.min(Lx, math.max(0, pos.x + along))
      elseif axis=='y' then pos.y = math.min(Ly, math.max(0, pos.y + along))
      else pos.z = math.min(Lz, math.max(0, pos.z + along))
      end
      if target=='mic' then
        set_param(P.mic_x, pos.x / Lx); set_param(P.mic_y, pos.y / Ly); set_param(P.mic_z, pos.z / Lz)
      else
        set_param(P.src_x, pos.x / Lx); set_param(P.src_y, pos.y / Ly); set_param(P.src_z, pos.z / Lz)
      end

      -- Tooltip while dragging gizmo
      local mx,my = im.GetMousePos(ctx)
      im.SetNextWindowPos(ctx, mx + 10, my + 10)
      im.BeginTooltip(ctx)
      if axis=='x' then
        local n = (pos.x / math.max(0.0001, Lx))
        local side = n < 0.5 and 'L' or (n > 0.5 and 'R' or 'C')
        if side == 'C' then
          im.Text(ctx, 'X: C')
        else
          local p = math.floor(math.abs((n - 0.5) / 0.5) * 100 + 0.5)
          im.Text(ctx, string.format('X: %d%% %s', p, side))
        end
      elseif axis=='y' then
        local p = math.floor((pos.y / math.max(0.0001, Ly)) * 100 + 0.5)
        im.Text(ctx, string.format('Y: %d%%', p))
      else
        local p = math.floor((pos.z / math.max(0.0001, Lz)) * 100 + 0.5)
        im.Text(ctx, string.format('Z: %d%%', p))
      end
      im.EndTooltip(ctx)
      if not IsLBtnHeld then st.draggingAxis=nil; st.axisActive=false end
    end

    -- Side: Wet & Dry knobs using AddKnob
    FX[FxGUID] = FX[FxGUID] or {}
    FX[FxGUID].ARV_Wet = FX[FxGUID].ARV_Wet or { Num = P.mix, CustomLbl = 'Wet', Lbl_Pos = 'Bottom' }
    FX[FxGUID].ARV_Dry = FX[FxGUID].ARV_Dry or { Num = P.dry, CustomLbl = 'Dry', Lbl_Pos = 'Bottom' }
    im.SetCursorScreenPos(ctx, sideL, viewT + 20)
    AddKnob(ctx, FxGUID, 'ARV_Wet', FX_Idx)
    im.SetCursorScreenPos(ctx, sideL, viewT + 90)
    AddKnob(ctx, FxGUID, 'ARV_Dry', FX_Idx)

    -- Show current dims following mapping: Width=X(from JSFX Width), Height=Y(from JSFX Height), Depth=Z(from JSFX Length)
    im.DrawList_AddText(WDL, sideL, viewT + 160, 0xB0B0B0ff, string.format('Width %.1fm', Lx))
    im.DrawList_AddText(WDL, sideL, viewT + 175, 0xB0B0B0ff, string.format('Height %.1fm', Ly))
    im.DrawList_AddText(WDL, sideL, viewT + 190, 0xB0B0B0ff, string.format('Depth %.1fm', Lz))

    -- Mic facing (deg) drag area
    local deg = get_param(P.mic_facing_deg)
    im.DrawList_AddText(WDL, sideL, viewT + 210, 0x909090ff, 'Facing')
    im.InvisibleButton(ctx, '##face'..FxGUID, 60, 20)
    local fL,fT = im.GetItemRectMin(ctx)
    im.DrawList_AddRect(WDL, fL, fT, fL+60, fT+20, 0x404040ff)
    im.DrawList_AddText(WDL, fL+6, fT+3, 0xC0C0C0ff, string.format('%3.0f°', deg*360))
    if im.IsItemActive(ctx) and IsLBtnHeld then
      local dx, _ = im.GetMouseDelta(ctx)
      deg = math.min(1, math.max(0, deg + dx*0.002))
      set_param(P.mic_facing_deg, deg)
    end

    im.EndChild(ctx)
  end
end

-- Particle system (module-level, simple)
fx.__arv_particles = fx.__arv_particles or {list={}, last_stamp=0}
local Psys = fx.__arv_particles

local function spawn_particles(num, color, origin)
  for i=1,num do
    local p = {
      x = origin.x, y = origin.y, z = origin.z,
      vx = (math.random()-0.5)*2, vy = (math.random()-0.5)*1.2 + 0.3, vz = (math.random()-0.5)*2,
      life = 1.0, clr = color,
    }
    table.insert(Psys.list, p)
  end
end

local function update_particles(dt, Lx, Ly, Lz, alpha)
  local k = 0.98 -- air drag
  local bounce = 0.6 * (1 - alpha) + 0.2
  for i=#Psys.list,1,-1 do
    local p = Psys.list[i]
    p.vy = p.vy - 0.2*dt
    p.x = p.x + p.vx*dt
    p.y = p.y + p.vy*dt
    p.z = p.z + p.vz*dt
    p.vx = p.vx*k; p.vy = p.vy*k; p.vz = p.vz*k
    -- collide with room bounds
    if p.x < 0 then p.x=0; p.vx = -p.vx*bounce end
    if p.x > Lx then p.x=Lx; p.vx = -p.vx*bounce end
    if p.y < 0 then p.y=0; p.vy = -p.vy*bounce end
    if p.y > Ly then p.y=Ly; p.vy = -p.vy*bounce end
    if p.z < 0 then p.z=0; p.vz = -p.vz*bounce end
    if p.z > Lz then p.z=Lz; p.vz = -p.vz*bounce end
    p.life = p.life - dt*0.20
    if p.life <= 0 then table.remove(Psys.list, i) end
  end
end

local function render_particles(rot_project_fn, WDL)
  for _,p in ipairs(Psys.list) do
    local sx,sy,sz = rot_project_shape(p.x,p.y,p.z)
    local r = 2 + (1 - math.min(1, math.abs(sz)/50)) * 2
    im.DrawList_AddCircleFilled(WDL, sx, sy, r, p.clr)
  end
end


