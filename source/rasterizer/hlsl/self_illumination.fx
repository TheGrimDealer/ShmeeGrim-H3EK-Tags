
PARAM(float, self_illum_intensity);

float3 calc_self_illumination_none_ps(
	in float2 texcoord,
	inout float3 albedo_times_light,
	in float3 view_dir)
{
	return float3(0.0f, 0.0f, 0.0f);
}

PARAM_SAMPLER_2D(self_illum_map);
PARAM(float4, self_illum_map_xform);
PARAM(float4, self_illum_color);

float3 calc_self_illumination_simple_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float4 result= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)) * self_illum_color;		// ###ctchou $PERF roll self_illum_intensity into self_illum_color
	result.rgb *= self_illum_intensity;
	
	return result.rgb;
}

float3 calc_self_illumination_simple_with_alpha_mask_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float4 result= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)) * self_illum_color;		// ###ctchou $PERF roll self_illum_intensity into self_illum_color
	result.rgb *= result.a * self_illum_intensity;
	
	return result.rgb;
}


PARAM_SAMPLER_2D(alpha_mask_map);
PARAM_SAMPLER_2D(noise_map_a);
PARAM_SAMPLER_2D(noise_map_b);
PARAM(float4, alpha_mask_map_xform);
PARAM(float4, noise_map_a_xform);
PARAM(float4, noise_map_b_xform);
PARAM(float4, color_medium);
PARAM(float4, color_sharp);
PARAM(float4, color_wide);
PARAM(float, thinness_medium);
PARAM(float, thinness_sharp);
PARAM(float, thinness_wide);

float3 calc_self_illumination_plasma_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float alpha=	sample2D(alpha_mask_map, transform_texcoord(texcoord, alpha_mask_map_xform)).a;
	float noise_a=	sample2D(noise_map_a, transform_texcoord(texcoord, noise_map_a_xform)).r;
	float noise_b=	sample2D(noise_map_b, transform_texcoord(texcoord, noise_map_b_xform)).r;

	float diff= 1.0f - abs(noise_a-noise_b);
	float medium_diff= pow(diff, thinness_medium);
	float sharp_diff= pow(diff, thinness_sharp);
	float wide_diff= pow(diff, thinness_wide);

	wide_diff-= medium_diff;
	medium_diff-= sharp_diff;
	
	float3 color= color_medium.rgb*color_medium.a*medium_diff + color_sharp.rgb*color_sharp.a*sharp_diff + color_wide.rgb*color_wide.a*wide_diff;
	
	return color*alpha*self_illum_intensity;
}

PARAM(float4, channel_a);
PARAM(float4, channel_b);
PARAM(float4, channel_c);

float3 calc_self_illumination_three_channel_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float4 self_illum= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform));

	self_illum.rgb=		self_illum.r	*	channel_a.a *	channel_a.rgb +
						self_illum.g	*	channel_b.a	*	channel_b.rgb +
						self_illum.b	*	channel_c.a	*	channel_c.rgb;

	return self_illum.rgb * self_illum_intensity;
}

float3 calc_self_illumination_from_albedo_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float3 self_illum= albedo*self_illum_color.xyz*self_illum_intensity;
	albedo= float3(0.f, 0.f, 0.f);
	
	return(self_illum);
}



PARAM_SAMPLER_2D(self_illum_detail_map);
PARAM(float4, self_illum_detail_map_xform);


float3 calc_self_illumination_detail_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float4 self_illum=			sample2D(self_illum_map,			transform_texcoord(texcoord, self_illum_map_xform));
	float4 self_illum_detail=	sample2D(self_illum_detail_map,		transform_texcoord(texcoord, self_illum_detail_map_xform));
	float4 result= self_illum * (self_illum_detail * DETAIL_MULTIPLIER) * self_illum_color;
	
	result.rgb *= self_illum_intensity;

	return result.rgb;
}

PARAM_SAMPLER_2D(meter_map);
PARAM(float4, meter_map_xform);
PARAM(float4, meter_color_off);
PARAM(float4, meter_color_on);
PARAM(float, meter_value);

float3 calc_self_illumination_meter_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float4 meter_map_sample= sample2D(meter_map, transform_texcoord(texcoord, meter_map_xform));
	return (meter_map_sample.x>= 0.5f)
		? (meter_value>= meter_map_sample.w)
			? meter_color_on.xyz 
			: meter_color_off.xyz
		: float3(0,0,0);
}

// PARAM(float3, primary_change_color);
PARAM(float, primary_change_color_blend);

float3 calc_self_illumination_times_diffuse_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float3 self_illum_texture_sample= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	
	float albedo_blend= max(self_illum_texture_sample.g * 10.0 - 9.0, 0.0);
	float3 albedo_part= albedo_blend + (1-albedo_blend) * albedo;
	float3 mix_illum_color = (primary_change_color_blend * primary_change_color.xyz) + ((1 - primary_change_color_blend) * self_illum_color.xyz);	
	float3 self_illum= albedo_part * mix_illum_color * self_illum_intensity * self_illum_texture_sample;
	
	return(self_illum);

}

float3 calc_self_illumination_holograms_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float3 self_illum_texture_sample= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	
	float albedo_blend= max(self_illum_texture_sample.g * 10.0 - 9.0, 0.0);
	float3 albedo_part= albedo_blend + (1-albedo_blend) * albedo;
	float3 self_illum= albedo_part * self_illum_color.xyz * self_illum_intensity * self_illum_texture_sample;
	
	return(self_illum);
}

float3 calc_self_illumination_change_color_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float3 self_illum_texture_sample= sample2D(self_illum_map, transform_texcoord(texcoord, self_illum_map_xform)).rgb;
	
	float3 mix_illum_color = (primary_change_color_blend * primary_change_color.xyz) + ((1 - primary_change_color_blend) * self_illum_color.xyz);	
	float3 self_illum= mix_illum_color * self_illum_intensity * self_illum_texture_sample;
	
	return(self_illum);

}



PARAM_SAMPLER_2D(illum_index_map);
PARAM(float4, illum_index_map_xform);
PARAM(float, index_selection);
PARAM(float, left_falloff);
PARAM(float, right_falloff);

float3 calc_self_illumination_palette_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	float illum_index= sample2D(illum_index_map, transform_texcoord(texcoord, illum_index_map_xform)).x;
	
	float illum= (illum_index - index_selection);
	float falloff= (illum < 0.0f ? left_falloff : right_falloff);
	illum= 1.0f - pow(abs(illum), falloff);
	
	float3 self_illum= illum * self_illum_color.rgb * self_illum_intensity;
	
	return self_illum;
}

/***************** custom ******************/

//PARAM_SAMPLER_3D(volumetric_map);
//PARAM(float, volumetric_depth);
//PARAM(int, num_sample_points);

float3 calc_self_illumination_volumetric_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	//float2 full_offset= view_dir.xy * -(1.0 / view_dir.z) * volumetric_depth;
	//float2 offset_single_step = full_offset / num_sample_points;
	//
	//float4 result= float4(0.0, 0.0, 0.0, 0.0);
	//for (int i=0; i < volumetric_depth; i++)
	//{
	//	float3 offset= float3(offset_single_step, 1.0 / num_sample_points);
	//	offset*= i;
	//	
	//	result+= sample3D(volumetric_map, offset + texcoord) / num_sample_points;
	//}
	//return result.rgb * result.a * self_illum_color * self_illum_intensity;
	return float3(0.0, 0.0, 0.0);
}

/***************** halo reach backports ******************/

PARAM_SAMPLER_2D(opacity_map);
PARAM(float4, opacity_map_xform);
PARAM(float, distance_fade_scale);

PARAM_SAMPLER_2D(walls);
PARAM(float4, walls_xform);
PARAM_SAMPLER_2D(floors);
PARAM(float4, floors_xform);
PARAM_SAMPLER_2D(ceiling);
PARAM(float4, ceiling_xform);

PARAM(float4, transform_xform);

float3 calc_self_illumination_window_room_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	// flip view direction to be incoming (pointing towards the surface)
	view_dir= -view_dir;

	// calculate the coordinate of the first wall we will intersect (x wall and y wall), by quantizing our current coordinate (and rounding up or down based on the view direction)
	float2 wall_coordinate_xy=	(floor(texcoord.xy * transform_xform.xy + transform_xform.zw + 0.5f + sign(view_dir.xy) * 0.5f) - transform_xform.zw) / transform_xform.xy;
	
	// calculate the distance each of the walls
	float2 distance_xy=			(wall_coordinate_xy - texcoord.xy) / view_dir.xy;

	// we hit the closest wall first.  calculate the intersection coordinates
	float3 intersection=		float3(texcoord.xy, 0) + min(distance_xy.x, distance_xy.y) * view_dir.xyz;
	
	float4 color;	
	if (distance_xy.x < distance_xy.y)
	{
		color=	sample2D(walls,	transform_texcoord(intersection.zy, walls_xform));
	}
	else
	{
		if (view_dir.y > 0)
		{
			color=	sample2D(floors,	transform_texcoord(intersection.xz, floors_xform));
		}
		else
		{
			color=	sample2D(ceiling,	transform_texcoord(intersection.xz, ceiling_xform));
		}
	}

	float falloff= saturate(1.0f + intersection.z * distance_fade_scale);
	float4 opacity=		sample2D(opacity_map, transform_texcoord(texcoord, opacity_map_xform));
	return color.rgb * self_illum_intensity * falloff * opacity.rgb;
}

float3 calc_self_illumination_blend_box_ps(
	in float2 texcoord,
	inout float3 albedo,
	in float3 view_dir)
{
	// flip view direction to be incoming (pointing towards the surface)
	view_dir= -view_dir;

	// calculate the coordinate of the first wall we will intersect (x wall and y wall), by quantizing our current coordinate (and rounding up or down based on the view direction)
	float2 wall_coordinate_xy=	floor(texcoord.xy + 0.5f + sign(view_dir.xy) * 0.5f);
	float2 wall_coordinate_xy2=	floor((texcoord.xy + 0.5f) + 0.5f + sign(view_dir.xy) * 0.5f);
	
	// calculate the distance each of the walls
	float2 distance_xy=				(wall_coordinate_xy - texcoord.xy) / view_dir.xy;
	float2 distance_xy2=			(wall_coordinate_xy2 - (texcoord.xy + 0.5f)) / view_dir.xy;

	// we hit the closest wall first.  calculate the intersection coordinates
	float3 intersection_x=		float3(texcoord.xy, 0) + distance_xy.x * view_dir.xyz;
	float3 intersection_y=		float3(texcoord.xy, 0) + distance_xy.y * view_dir.xyz;

	float3 intersection_x2=		float3(texcoord.xy + 0.5f, 0) + distance_xy2.x * view_dir.xyz;
	float3 intersection_y2=		float3(texcoord.xy + 0.5f, 0) + distance_xy2.y * view_dir.xyz;

	float3 dirweight=	view_dir.xyz * view_dir.xyz;
	dirweight	/=		(dirweight.x + dirweight.y + dirweight.z);

	float2 true_view=	view_dir.xy / -view_dir.z;

	float wall_factor=	2.0f * abs(0.5f - (texcoord.x - floor(texcoord.x)));
	float floor_factor=	2.0f * abs(0.5f - (texcoord.y - floor(texcoord.y)));

	float4 color=	0;
	float4	wall_color=		lerp(sample2D(walls,	intersection_x.zy + float2(intersection_x.x, 0.0f)), sample2D(walls,	intersection_x2.zy), wall_factor);
	float4	floor_color=	lerp(sample2D(floors,	intersection_y.xz + float2(0.0f, intersection_y.y)), sample2D(floors,	intersection_y2.xz), floor_factor);
	
	color +=	dirweight.x * wall_color;
	color +=	dirweight.y * floor_color;
	
	color +=	dirweight.z * sample2D(ceiling, texcoord.xy * 1.2 + 0.4 * true_view.xy);
	color +=	dirweight.z * sample2D(ceiling, texcoord.xy * 1.0 + 0.8 * true_view.xy + float2(0.0f, 0.5f));
	color +=	dirweight.z * sample2D(ceiling, texcoord.xy * 1.6 + 1.2 * true_view.xy + float2(0.5f, 0.0f));
	
	return color.rgb * self_illum_intensity;
}

