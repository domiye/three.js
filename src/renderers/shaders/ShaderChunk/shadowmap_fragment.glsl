#ifdef USE_SHADOWMAP

	#ifdef SHADOWMAP_DEBUG

		vec3 frustumColors[3];
		frustumColors[0] = vec3( 1.0, 0.5, 0.0 );
		frustumColors[1] = vec3( 0.0, 1.0, 0.8 );
		frustumColors[2] = vec3( 0.0, 0.5, 1.0 );

	#endif

	float fDepth;
	vec3 shadowColor = vec3( 1.0 );

	for( int i = 0; i < MAX_SHADOWS; i ++ ) {

		// to save on uniform space, we use the sign of @shadowDarkness[ i ] to determine
		// whether or not this light is a point light ( shadowDarkness[ i ] < 0 == point light)
		bool isPointLight = shadowDarkness[ i ] < 0.0;

		// get the real shadow darkness
		float realShadowDarkness = abs( shadowDarkness[ i ] );

		// for point lights, the uniform @vShadowCoord is re-purposed to hold
		// the distance from the light to the world-space position of the fragment.
		vec3 lightToPosition = vShadowCoord[ i ].xyz;

		float texelSizeX =  1.0 / shadowMapSize[ i ].x;
		float texelSizeY =  1.0 / shadowMapSize[ i ].y;

		vec3 shadowCoord = vShadowCoord[ i ].xyz / vShadowCoord[ i ].w;
		float shadow = 0.0;

		// if ( something && something ) breaks ATI OpenGL shader compiler
		// if ( all( something, something ) ) using this instead

		bvec4 inFrustumVec = bvec4 ( shadowCoord.x >= 0.0, shadowCoord.x <= 1.0, shadowCoord.y >= 0.0, shadowCoord.y <= 1.0 );
		bool inFrustum = all( inFrustumVec );

		bvec2 frustumTestVec = bvec2( inFrustum, shadowCoord.z <= 1.0 );

		bool frustumTest = all( frustumTestVec );

		if ( frustumTest || isPointLight ) {			

			#if defined( SHADOWMAP_TYPE_PCF )

				#if defined(POINT_LIGHT_SHADOWS)

					if( isPointLight ) {

						// bd3D = base direction 3D
						vec3 bd3D = normalize( lightToPosition );
						// dp = distance from light to fragment position
						float dp = length( lightToPosition );

						shadow = 0.0;						

						// base measurement
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D, texelSizeY ) ), shadowBias[ i ], shadow );

						// dr = disk radius
						const float dr = 1.25;
						// os = offset scale
						float os = dr *  2.0 * texelSizeY;

						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd0 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd1 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd2 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd3 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd4 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd5 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd6 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd7 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd8 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd9 * os, texelSizeY ) ), shadowBias[ i ], shadow );

						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd10 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd11 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd12 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd13 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd14 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd15 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd16 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd17 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd18 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd19 * os, texelSizeY ) ), shadowBias[ i ], shadow );

						shadow /= 21.0;

					} else {

				#endif

						// Percentage-close filtering
						// (9 pixel kernel)
						// http://fabiensanglard.net/shadowmappingPCF/
						
						/*
								// nested loops breaks shader compiler / validator on some ATI cards when using OpenGL
								// must enroll loop manually
							for ( float y = -1.25; y <= 1.25; y += 1.25 )
								for ( float x = -1.25; x <= 1.25; x += 1.25 ) {
									vec4 rgbaDepth = texture2D( shadowMap[ i ], vec2( x * xPixelOffset, y * yPixelOffset ) + shadowCoord.xy );
											// doesn't seem to produce any noticeable visual difference compared to simple texture2D lookup
											//vec4 rgbaDepth = texture2DProj( shadowMap[ i ], vec4( vShadowCoord[ i ].w * ( vec2( x * xPixelOffset, y * yPixelOffset ) + shadowCoord.xy ), 0.05, vShadowCoord[ i ].w ) );
									float fDepth = unpackDepth( rgbaDepth );
									if ( fDepth < shadowCoord.z )
										shadow += 1.0;
							}
							shadow /= 9.0;
						*/

						shadowCoord.z += shadowBias[ i ];

						const float shadowDelta = 1.0 / 9.0;

						float xPixelOffset = texelSizeX;
						float yPixelOffset = texelSizeY;

						float dx0 = -1.25 * xPixelOffset;
						float dy0 = -1.25 * yPixelOffset;
						float dx1 = 1.25 * xPixelOffset;
						float dy1 = 1.25 * yPixelOffset;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy0 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy0 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy0 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, 0.0 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, 0.0 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy1 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy1 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

						fDepth = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy1 ) ) );
						if ( fDepth < shadowCoord.z ) shadow += shadowDelta;

				#if defined(POINT_LIGHT_SHADOWS)

					}

				#endif

				shadowColor = shadowColor * vec3( ( 1.0 - realShadowDarkness * shadow ) );

			#elif defined( SHADOWMAP_TYPE_PCF_SOFT )

				#if defined(POINT_LIGHT_SHADOWS)

					if( isPointLight ) {

						// bd3D = base direction 3D
						vec3 bd3D = normalize( lightToPosition );
						// dp = distance from light to fragment position
						float dp = length( lightToPosition );

						shadow = 0.0;						

						// base measurement
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D, texelSizeY ) ), shadowBias[ i ], shadow );

						// dr = disk radius
						const float dr = 2.25;
						// os = offset scale
						float os = dr *  2.0 * texelSizeY;

						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd0 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd1 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd2 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd3 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd4 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd5 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd6 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd7 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd8 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd9 * os, texelSizeY ) ), shadowBias[ i ], shadow );

						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd10 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd11 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd12 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd13 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd14 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd15 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd16 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd17 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd18 * os, texelSizeY ) ), shadowBias[ i ], shadow );
						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D + gsd19 * os, texelSizeY ) ), shadowBias[ i ], shadow );

						shadow /= 21.0;

					} else {

				#endif

						// Percentage-close filtering
						// (9 pixel kernel)
						// http://fabiensanglard.net/shadowmappingPCF/

						shadowCoord.z += shadowBias[ i ];

						float xPixelOffset = texelSizeX;
						float yPixelOffset = texelSizeY;

						float dx0 = -1.0 * xPixelOffset;
						float dy0 = -1.0 * yPixelOffset;
						float dx1 = 1.0 * xPixelOffset;
						float dy1 = 1.0 * yPixelOffset;

						mat3 shadowKernel;
						mat3 depthKernel;

						depthKernel[0][0] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy0 ) ) );
						depthKernel[0][1] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, 0.0 ) ) );
						depthKernel[0][2] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx0, dy1 ) ) );
						depthKernel[1][0] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy0 ) ) );
						depthKernel[1][1] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy ) );
						depthKernel[1][2] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( 0.0, dy1 ) ) );
						depthKernel[2][0] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy0 ) ) );
						depthKernel[2][1] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, 0.0 ) ) );
						depthKernel[2][2] = unpackDepth( texture2D( shadowMap[ i ], shadowCoord.xy + vec2( dx1, dy1 ) ) );

						vec3 shadowZ = vec3( shadowCoord.z );
						shadowKernel[0] = vec3(lessThan(depthKernel[0], shadowZ ));
						shadowKernel[0] *= vec3(0.25);

						shadowKernel[1] = vec3(lessThan(depthKernel[1], shadowZ ));
						shadowKernel[1] *= vec3(0.25);

						shadowKernel[2] = vec3(lessThan(depthKernel[2], shadowZ ));
						shadowKernel[2] *= vec3(0.25);

						vec2 fractionalCoord = 1.0 - fract( shadowCoord.xy * shadowMapSize[i].xy );

						shadowKernel[0] = mix( shadowKernel[1], shadowKernel[0], fractionalCoord.x );
						shadowKernel[1] = mix( shadowKernel[2], shadowKernel[1], fractionalCoord.x );

						vec4 shadowValues;
						shadowValues.x = mix( shadowKernel[0][1], shadowKernel[0][0], fractionalCoord.y );
						shadowValues.y = mix( shadowKernel[0][2], shadowKernel[0][1], fractionalCoord.y );
						shadowValues.z = mix( shadowKernel[1][1], shadowKernel[1][0], fractionalCoord.y );
						shadowValues.w = mix( shadowKernel[1][2], shadowKernel[1][1], fractionalCoord.y );

						shadow = dot( shadowValues, vec4( 1.0 ) );

				#if defined(POINT_LIGHT_SHADOWS)
					
					}

				#endif

				shadowColor = shadowColor * vec3( ( 1.0 - realShadowDarkness * shadow ) );

			#else

				#if defined(POINT_LIGHT_SHADOWS)

					if( isPointLight ) {

						vec3 bd3D = normalize( lightToPosition );
						float dp = length( lightToPosition );

						float shadow = 0.0;

						adjustShadowValue1K( dp, texture2D( shadowMap[ i ], cubeToUV( bd3D, texelSizeY ) ), shadowBias[ i ], shadow );

						shadowColor = shadowColor * vec3( 1.0 - realShadowDarkness * shadow );

					} else {

				#endif
						shadowCoord.z += shadowBias[ i ];

						vec4 rgbaDepth = texture2D( shadowMap[ i ], shadowCoord.xy );
						float fDepth = unpackDepth( rgbaDepth );

						if ( fDepth < shadowCoord.z )

						// spot with multiple shadows is darker

						shadowColor = shadowColor * vec3( 1.0 - realShadowDarkness );

						// spot with multiple shadows has the same color as single shadow spot

						// 	shadowColor = min( shadowColor, vec3( realShadowDarkness ) );

				#if defined(POINT_LIGHT_SHADOWS)

					}

				#endif

			#endif

		}


		#ifdef SHADOWMAP_DEBUG

			if ( inFrustum ) outgoingLight *= frustumColors[ i ];

		#endif

	}

	outgoingLight = outgoingLight * shadowColor;

#endif
