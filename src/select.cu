/*
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include "cm.h"
#include "zone_map.h"


using namespace mgpu;

vector<void*> alloced_mem;

template<typename T>
struct distinct : public binary_function<T,T,T>
{
    __host__ __device__ T operator()(const T &lhs, const T &rhs) const {
        return lhs != rhs;
    }
};


struct gpu_getyear
{
	const int_type *source;
    int_type *dest;
		
	gpu_getyear(const int_type *_source, int_type *_dest):
			  source(_source), dest(_dest) {}
    template <typename IndexType>
    __host__ __device__
    void operator()(const IndexType & i) {	
		
		uint64 sec;
		uint quadricentennials, centennials, quadrennials, annuals/*1-ennial?*/;
		uint year, leap;
		uint yday;
		uint month, mday;
		const uint daysSinceJan1st[2][13]=
		{
			{0,31,59,90,120,151,181,212,243,273,304,334,365}, // 365 days, non-leap
			{0,31,60,91,121,152,182,213,244,274,305,335,366}  // 366 days, leap
		};
		uint64 SecondsSinceEpoch = source[i]/1000;
		sec = SecondsSinceEpoch + 11644473600;

		//wday = (uint)((sec / 86400 + 1) % 7); // day of week
		quadricentennials = (uint)(sec / 12622780800ULL); // 400*365.2425*24*3600
		sec %= 12622780800ULL;

		centennials = (uint)(sec / 3155673600ULL); // 100*(365+24/100)*24*3600
		if (centennials > 3)
		{
			centennials = 3;
		}
		sec -= centennials * 3155673600ULL;

		quadrennials = (uint)(sec / 126230400); // 4*(365+1/4)*24*3600
		if (quadrennials > 24)
		{
			quadrennials = 24;
		}
		sec -= quadrennials * 126230400ULL;

		annuals = (uint)(sec / 31536000); // 365*24*3600
		if (annuals > 3)
		{
			annuals = 3;
		}
		sec -= annuals * 31536000ULL;

		year = 1601 + quadricentennials * 400 + centennials * 100 + quadrennials * 4 + annuals;
		leap = !(year % 4) && (year % 100 || !(year % 400));

		// Calculate the day of the year and the time
		yday = sec / 86400;
		sec %= 86400;
		//hour = sec / 3600;
		sec %= 3600;
		//min = sec / 60;
		sec %= 60;

	// Calculate the month
		for (mday = month = 1; month < 13; month++)
		{
			if (yday < daysSinceJan1st[leap][month])
			{
			mday += yday - daysSinceJan1st[leap][month - 1];
			break;
			}
		}
		dest[i] = year;		
	}
};	

struct gpu_getmonth
{
	const int_type *source;
    int_type *dest;
		
	gpu_getmonth(const int_type *_source, int_type *_dest):
			  source(_source), dest(_dest) {}
    template <typename IndexType>
    __host__ __device__
    void operator()(const IndexType & i) {	
		
		uint64 sec;
		uint quadricentennials, centennials, quadrennials, annuals/*1-ennial?*/;
		uint year, leap;
		uint yday;
		uint month, mday;
		const uint daysSinceJan1st[2][13]=
		{
			{0,31,59,90,120,151,181,212,243,273,304,334,365}, // 365 days, non-leap
			{0,31,60,91,121,152,182,213,244,274,305,335,366}  // 366 days, leap
		};
		uint64 SecondsSinceEpoch = source[i]/1000;
		sec = SecondsSinceEpoch + 11644473600;

		//wday = (uint)((sec / 86400 + 1) % 7); // day of week
		quadricentennials = (uint)(sec / 12622780800ULL); // 400*365.2425*24*3600
		sec %= 12622780800ULL;

		centennials = (uint)(sec / 3155673600ULL); // 100*(365+24/100)*24*3600
		if (centennials > 3)
		{
			centennials = 3;
		}
		sec -= centennials * 3155673600ULL;

		quadrennials = (uint)(sec / 126230400); // 4*(365+1/4)*24*3600
		if (quadrennials > 24)
		{
			quadrennials = 24;
		}
		sec -= quadrennials * 126230400ULL;

		annuals = (uint)(sec / 31536000); // 365*24*3600
		if (annuals > 3)
		{
			annuals = 3;
		}
		sec -= annuals * 31536000ULL;

		year = 1601 + quadricentennials * 400 + centennials * 100 + quadrennials * 4 + annuals;
		leap = !(year % 4) && (year % 100 || !(year % 400));

		// Calculate the day of the year and the time
		yday = sec / 86400;
		sec %= 86400;
		//hour = sec / 3600;
		sec %= 3600;
		//min = sec / 60;
		sec %= 60;

	// Calculate the month
		for (mday = month = 1; month < 13; month++)
		{
			if (yday < daysSinceJan1st[leap][month])
			{
			mday += yday - daysSinceJan1st[leap][month - 1];
			break;
			}
		}
		dest[i] = year*100+month;		
	}
};	


struct gpu_getday
{
	const int_type *source;
    int_type *dest;
		
	gpu_getday(const int_type *_source, int_type *_dest):
			  source(_source), dest(_dest) {}
    template <typename IndexType>
    __host__ __device__
    void operator()(const IndexType & i) {	
		
		uint64 sec;
		uint quadricentennials, centennials, quadrennials, annuals/*1-ennial?*/;
		uint year, leap;
		uint yday, hour, min;
		uint month, mday, wday;
		const uint daysSinceJan1st[2][13]=
		{
			{0,31,59,90,120,151,181,212,243,273,304,334,365}, // 365 days, non-leap
			{0,31,60,91,121,152,182,213,244,274,305,335,366}  // 366 days, leap
		};
		uint64 SecondsSinceEpoch = source[i]/1000;
		sec = SecondsSinceEpoch + 11644473600;

		wday = (uint)((sec / 86400 + 1) % 7); // day of week
		quadricentennials = (uint)(sec / 12622780800ULL); // 400*365.2425*24*3600
		sec %= 12622780800ULL;

		centennials = (uint)(sec / 3155673600ULL); // 100*(365+24/100)*24*3600
		if (centennials > 3)
		{
			centennials = 3;
		}
		sec -= centennials * 3155673600ULL;

		quadrennials = (uint)(sec / 126230400); // 4*(365+1/4)*24*3600
		if (quadrennials > 24)
		{
			quadrennials = 24;
		}
		sec -= quadrennials * 126230400ULL;

		annuals = (uint)(sec / 31536000); // 365*24*3600
		if (annuals > 3)
		{
			annuals = 3;
		}
		sec -= annuals * 31536000ULL;

		year = 1601 + quadricentennials * 400 + centennials * 100 + quadrennials * 4 + annuals;
		leap = !(year % 4) && (year % 100 || !(year % 400));

		// Calculate the day of the year and the time
		yday = sec / 86400;
		sec %= 86400;
		hour = sec / 3600;
		sec %= 3600;
		min = sec / 60;
		sec %= 60;

	// Calculate the month
		for (mday = month = 1; month < 13; month++)
		{
			if (yday < daysSinceJan1st[leap][month])
			{
			mday += yday - daysSinceJan1st[leap][month - 1];
			break;
			}
		}
		dest[i] = year*10000+month*100+mday;		
	}
};	



void select(queue<string> op_type, queue<string> op_value, queue<int_type> op_nums, queue<float_type> op_nums_f, queue<unsigned int> op_nums_precision, CudaSet* a,
            CudaSet* b, vector<thrust::device_vector<int_type> >& distinct_tmp, bool& one_liner)
{

    stack<string> exe_type;
    stack<string> exe_value;
    stack<int_type*> exe_vectors;
    stack<int_type> exe_nums;
    string  s1, s2, s1_val, s2_val;
    int_type n1, n2, res;
    unsigned int colCount = 0;
    stack<int> col_type;
    string grp_type;
    stack<string> grp_type1;
    stack<string> col_val;
    size_t res_size = 0;

    stack<string> exe_value1;
    stack<int_type*> exe_vectors1;
    stack<float_type*> exe_vectors1_d;
    stack<int_type> exe_nums1;
	stack<unsigned int> exe_precision;
	stack<unsigned int> exe_precision1;
	bool ts;
	stack<bool> exe_ts;
    stack<float_type*> exe_vectors_f;
    stack<float_type> exe_nums_f;
    float_type n1_f, n2_f, res_f;
    bool one_line;
    unsigned int dist_processed = 0;
    bool prep = 0;
    one_line = 0;

    thrust::device_ptr<bool> d_di(thrust::raw_pointer_cast(a->grp.data()));
    std::auto_ptr<ReduceByKeyPreprocessData> ppData;
	
    if (a->grp_count && (a->mRecCount != 0))
        res_size = a->grp_count;
		
	std::clock_t start1 = std::clock();	

    for(int i=0; !op_type.empty(); ++i, op_type.pop()) {

        string ss = op_type.front();
        //cout << ss << endl;

        if(ss.compare("emit sel_name") != 0) {
            grp_type = "NULL";

            if (ss.compare("COUNT") == 0  || ss.compare("SUM") == 0  || ss.compare("AVG") == 0 || ss.compare("MIN") == 0 || ss.compare("MAX") == 0 || ss.compare("DISTINCT") == 0 || ss.compare("YEAR") == 0 || ss.compare("MONTH") == 0 || ss.compare("DAY") == 0) {
			
                if(!prep && a->grp_count) {
                    mgpu::ReduceByKeyPreprocess<float_type>((int)a->mRecCount, thrust::raw_pointer_cast(d_di),
                                                            (bool*)0, head_flag_predicate<bool>(), (int*)0, (int*)0,
                                                            &ppData, *context);
                    prep = 1;
                };


                if(!a->grp_count && ss.compare("YEAR") && ss.compare("MONTH") && ss.compare("DAY")) {
                    one_line = 1;
				};	
				
				
				if (ss.compare("YEAR") == 0) {	
					s1_val = exe_value.top();
                    exe_value.pop();
					exe_type.pop();
					thrust::device_ptr<int_type> res = thrust::device_malloc<int_type>(a->mRecCount);
					if(a->ts_cols[s1_val]) {						
						thrust::counting_iterator<unsigned int> begin(0);
						gpu_getyear ff((const int_type*)thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()),	thrust::raw_pointer_cast(res));
						thrust::for_each(begin, begin + a->mRecCount, ff);						
						exe_precision.push(0);			
					}
					else {
						thrust::transform(a->d_columns_int[s1_val].begin(), a->d_columns_int[s1_val].begin() + a->mRecCount, thrust::make_constant_iterator(10000), res, thrust::divides<int_type>());
						exe_precision.push(a->decimal_zeroes[s1_val]);			
					};	
                    exe_vectors.push(thrust::raw_pointer_cast(res));
                    exe_type.push("VECTOR");					
				}
				else if (ss.compare("MONTH") == 0) {	
					s1_val = exe_value.top();
                    exe_value.pop();
					exe_type.pop();
					thrust::device_ptr<int_type> res = thrust::device_malloc<int_type>(a->mRecCount);
					thrust::counting_iterator<unsigned int> begin(0);
					gpu_getmonth ff((const int_type*)thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()),	thrust::raw_pointer_cast(res));
					thrust::for_each(begin, begin + a->mRecCount, ff);						
					exe_precision.push(0);			
                    exe_vectors.push(thrust::raw_pointer_cast(res));
                    exe_type.push("VECTOR");					
				}				
				else if (ss.compare("DAY") == 0) {	
					s1_val = exe_value.top();
                    exe_value.pop();
					exe_type.pop();
					thrust::device_ptr<int_type> res = thrust::device_malloc<int_type>(a->mRecCount);
					thrust::counting_iterator<unsigned int> begin(0);
					gpu_getday ff((const int_type*)thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()),	thrust::raw_pointer_cast(res));
					thrust::for_each(begin, begin + a->mRecCount, ff);						
					exe_precision.push(0);			
                    exe_vectors.push(thrust::raw_pointer_cast(res));
                    exe_type.push("VECTOR");					
				}
				else if (ss.compare("DISTINCT") == 0) {
                    s1_val = exe_value.top();
                    exe_type.pop();
                    exe_value.pop();

                    if(a->type[s1_val] == 0) {

                        thrust::copy(a->d_columns_int[s1_val].begin(), a->d_columns_int[s1_val].begin() + a->mRecCount,
                                     distinct_tmp[dist_processed].begin());
                        dist_processed++;
                        thrust::device_ptr<int_type> res = thrust::device_malloc<int_type>(res_size);
                        exe_vectors.push(thrust::raw_pointer_cast(res));
                        exe_type.push("VECTOR");
                    }
                    else if(a->type[s1_val] == 2) {
                        //will add a DISTINCT on strings if anyone needs it
                        cout << "DISTINCT on strings is not supported yet" << endl;
                        exit(0);
                    }
                    else {
                        cout << "DISTINCT on float is not supported yet" << endl;
                        exit(0);
                    };
                }

                else if (ss.compare("COUNT") == 0) {

                    s1 = exe_type.top();
                    if(s1.compare("VECTOR") != 0) {  // non distinct

                        grp_type = "COUNT";
                        exe_type.pop();
                        s1_val = exe_value.top();
                        exe_value.pop();


                        if (a->grp_count) {
                            thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
							if(alloced_mem.empty()) {		
								alloc_pool(a->maxRecs);
							};
							thrust::device_ptr<int_type> const_seq((int_type*)alloced_mem.back());								
                            thrust::fill(const_seq, const_seq+a->mRecCount, (int_type)1);
                            ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(const_seq), (int_type)0,
                                             mgpu::plus<int_type>(), thrust::raw_pointer_cast(count_diff), *context);

                            //thrust::device_free(const_seq);
                            //thrust::reduce_by_key(d_di, d_di+(a->mRecCount), thrust::constant_iterator<int_type>(1),
                            //                      thrust::make_discard_iterator(), count_diff,
                            //                      head_flag_predicate<bool>(),thrust::plus<int_type>());

                            exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                            exe_type.push("VECTOR");
                        }
                        else {
                            thrust::device_ptr<int_type> dest  = thrust::device_malloc<int_type>(1);
                            dest[0] = a->mRecCount;
                            exe_vectors.push(thrust::raw_pointer_cast(dest));
                            exe_type.push("VECTOR");
                        };						
                    }
                    else
                        grp_type = "COUNTD";
					exe_precision.push(0);	

                }
                else if (ss.compare("SUM") == 0) {
				
                    /*if(op_case) {
                    	cout << "found case " << endl;
                    	op_case = 0;
                    	while(!exe_type.empty())
                    	{
                    	cout << "CASE type " << exe_type.top() << endl;
                    	exe_type.pop();
                    	exit(0);
                    	}

                    };
                    */

                    grp_type = "SUM";
                    s1 = exe_type.top();
                    exe_type.pop();

                    if (s1.compare("VECTOR F") == 0) {
                        float_type* s3 = exe_vectors_f.top();
                        exe_vectors_f.pop();

                        if (a->grp_count) {
                            thrust::device_ptr<float_type> source((float_type*)(s3));
                            thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(res_size);
                            ReduceByKeyApply(*ppData, s3, (float_type)0,
                                             mgpu::plus<float_type>(), thrust::raw_pointer_cast(count_diff), *context);
                            //thrust::reduce_by_key(d_di, d_di + a->mRecCount, source,
                            //                      thrust::make_discard_iterator(), count_diff,
                            //                      head_flag_predicate<bool>(),thrust::plus<float_type>());

                            exe_vectors_f.push(thrust::raw_pointer_cast(count_diff));
                            exe_type.push("VECTOR F");
                        }
                        else {
                            thrust::device_ptr<float_type> source((float_type*)(s3));
                            thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(1);
                            count_diff[0] = mgpu::Reduce(thrust::raw_pointer_cast(source), a->mRecCount, *context);
                            exe_vectors_f.push(thrust::raw_pointer_cast(count_diff));
                            exe_type.push("VECTOR F");
                            a->mRecCount = 1;
                        };
                        cudaFree(s3);
                    }
                    if (s1.compare("VECTOR") == 0) {

                        int_type* s3 = exe_vectors.top();
                        exe_vectors.pop();

                        if (a->grp_count) {
                            thrust::device_ptr<int_type> source((int_type*)(s3));
                            thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                            ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(source), (int_type)0,
                                             mgpu::plus<int_type>(), thrust::raw_pointer_cast(count_diff), *context);
                            exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                            exe_type.push("VECTOR");
                        }
                        else {
                            thrust::device_ptr<int_type> source((int_type*)(s3));
                            thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(1);
                            count_diff[0] = mgpu::Reduce(thrust::raw_pointer_cast(source), a->mRecCount, *context);
                            exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                            exe_type.push("VECTOR");
                        };
                        cudaFree(s3);
                    }

                    else if (s1.compare("NAME") == 0) {
                        s1_val = exe_value.top();
                        exe_value.pop();
						
                        if (a->grp_count) {

                            if(a->type[s1_val] == 0) {
                                thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                                ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()), (int_type)0,
                                                 mgpu::plus<int_type>(), thrust::raw_pointer_cast(count_diff), *context);
                                exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                                exe_type.push("VECTOR");
                            }
                            else if(a->type[s1_val] == 1) {
                                thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(res_size);
                                ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_float[s1_val].data()), (float_type)0,
                                                 mgpu::plus<float_type>(), thrust::raw_pointer_cast(count_diff), *context);
                                exe_vectors_f.push(thrust::raw_pointer_cast(count_diff));
                                exe_type.push("VECTOR F");
                            }
                        }
                        else {
                            if(a->type[s1_val] == 0) {
                                thrust::device_ptr<int_type> dest;
                                int_type cc = mgpu::Reduce(thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()), a->mRecCount, *context);
                                if (one_line) {
                                    dest = thrust::device_malloc<int_type>(1);
                                    dest[0] = cc;
                                }
                                else {
                                    dest = thrust::device_malloc<int_type>(a->mRecCount);
                                    thrust::sequence(dest, dest+(a->mRecCount), cc, (int_type)0);
                                };
                                exe_vectors.push(thrust::raw_pointer_cast(dest));
                                exe_type.push("VECTOR");
                            }
                            else if(a->type[s1_val] == 1) {
                                thrust::device_ptr<float_type> dest;
                                float_type cc = mgpu::Reduce(thrust::raw_pointer_cast(a->d_columns_float[s1_val].data()), a->mRecCount, *context);

                                if (one_line) {
                                    dest = thrust::device_malloc<float_type>(1);
                                    dest[0] = cc;
                                }
                                else {
                                    dest = thrust::device_malloc<float_type>(a->mRecCount);
                                    thrust::sequence(dest, dest+a->mRecCount, cc, (float_type)0);
                                };
                                exe_vectors_f.push(thrust::raw_pointer_cast(dest));
                                exe_type.push("VECTOR F");
                            };
                        };
						exe_precision.push(a->decimal_zeroes[s1_val]);
                    }
                }
                else if (ss.compare("MIN") == 0) {
				
                    grp_type = "MIN";
                    s1 = exe_type.top();
                    exe_type.pop();

                    s1_val = exe_value.top();
                    exe_value.pop();
					
					if(alloced_mem.empty()) {								
						alloc_pool(a->maxRecs);
					};
					thrust::device_ptr<unsigned int> d_di1((unsigned int*)alloced_mem.back());								
						
					thrust::copy(d_di, d_di+a->mRecCount,d_di1);
					thrust::exclusive_scan(d_di1, d_di1+a->mRecCount, d_di1);
					thrust::equal_to<unsigned int> binary_pred;					  
					

                    if(a->type[s1_val] == 0) {

                        thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                        //ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()), (int_type)0,
                        //                 mgpu::minimum<int_type>(), thrust::raw_pointer_cast(count_diff), *context);
						thrust::reduce_by_key(d_di1, d_di1+a->mRecCount, a->d_columns_int[s1_val].begin(),
                                              thrust::make_discard_iterator(), count_diff,
                                              binary_pred, thrust::minimum<int_type>());                        
                        exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                        exe_type.push("VECTOR");

                    }
                    else if(a->type[s1_val] == 1) {			

                        thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(res_size);
                        //ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_float[s1_val].data()), (float_type)0,
                        	//					mgpu::minimum<float_type>(), thrust::raw_pointer_cast(count_diff), *context);

						
                        thrust::reduce_by_key(d_di1, d_di1+a->mRecCount, a->d_columns_float[s1_val].begin(),
                                              thrust::make_discard_iterator(), count_diff,
                                              binary_pred, thrust::minimum<float_type>());
                        exe_vectors_f.push(thrust::raw_pointer_cast(count_diff));
                        exe_type.push("VECTOR F");
                    }
					exe_precision.push(a->decimal_zeroes[s1_val]);
                }
                else if (ss.compare("MAX") == 0) {

                    grp_type = "MAX";
                    s1 = exe_type.top();
                    exe_type.pop();

                    s1_val = exe_value.top();
                    exe_value.pop();

                    if(a->type[s1_val] == 0) {

                        thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                        ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()), (int_type)0,
                                         mgpu::maximum<int_type>(), thrust::raw_pointer_cast(count_diff), *context);
                        exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                        exe_type.push("VECTOR");

                    }
                    else if(a->type[s1_val] == 1) {

                        thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(res_size);
                        ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_float[s1_val].data()), (float_type)0,
                                         mgpu::maximum<float_type>(), thrust::raw_pointer_cast(count_diff), *context);


                        //thrust::reduce_by_key(d_di, d_di+(a->mRecCount), a->d_columns_float[s1_val].begin(),
                        //                      thrust::make_discard_iterator(), count_diff,
                        //                      head_flag_predicate<bool>(), thrust::maximum<float_type>());

                        exe_vectors_f.push(thrust::raw_pointer_cast(count_diff));
                        exe_type.push("VECTOR F");
                    }
					exe_precision.push(a->decimal_zeroes[s1_val]);
                }

                else if (ss.compare("AVG") == 0) {
                    grp_type = "AVG";
                    s1 = exe_type.top();
                    exe_type.pop();

                    s1_val = exe_value.top();
                    exe_value.pop();

                    if(a->type[s1_val] == 0) {

                        thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                        ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_int[s1_val].data()), (int_type)0,
                                         mgpu::plus<int_type>(), thrust::raw_pointer_cast(count_diff), *context);

                        exe_vectors.push(thrust::raw_pointer_cast(count_diff));
                        exe_type.push("VECTOR");
                    }
                    else if(a->type[s1_val] == 1) {

                        thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(res_size);
                        ReduceByKeyApply(*ppData, thrust::raw_pointer_cast(a->d_columns_float[s1_val].data()), (float_type)0,
                                         mgpu::plus<float_type>(), thrust::raw_pointer_cast(count_diff), *context);
                        exe_vectors_f.push(thrust::raw_pointer_cast(count_diff));
                        exe_type.push("VECTOR F");
                    }
					exe_precision.push(a->decimal_zeroes[s1_val]);
                };
            };

            if (ss.compare("NAME") == 0 || ss.compare("NUMBER") == 0 || ss.compare("FLOAT") == 0 || ss.compare("VECTOR") == 0 || ss.compare("VECTOR F") == 0) {

                exe_type.push(ss);
                if (ss.compare("NUMBER") == 0) {
                    exe_nums.push(op_nums.front());
                    op_nums.pop();
					exe_precision.push(op_nums_precision.front());
					op_nums_precision.pop();
                }
                if (ss.compare("FLOAT") == 0) {
                    exe_nums_f.push(op_nums_f.front());
                    op_nums_f.pop();
                }
                else if (ss.compare("NAME") == 0) {
                    exe_value.push(op_value.front());
					ts = a->ts_cols[op_value.front()];
                    op_value.pop();					
                }
            }
            else {
                if (ss.compare("MUL") == 0  || ss.compare("ADD") == 0 || ss.compare("DIV") == 0 || ss.compare("MINUS") == 0) {
                    // get 2 values from the stack
                    s1 = exe_type.top();
                    exe_type.pop();
                    s2 = exe_type.top();
                    exe_type.pop();

                    if (s1.compare("NUMBER") == 0 && s2.compare("NUMBER") == 0) {
                        n1 = exe_nums.top();
                        exe_nums.pop();
                        n2 = exe_nums.top();
                        exe_nums.pop();
						
						auto p1 = exe_precision.top();
						exe_precision.pop();
						auto p2 = exe_precision.top();
						exe_precision.pop();					
						auto pres = precision_func(p1, p2, ss);	
						exe_precision.push(pres);
						if(p1) 
							n1 = n1*(unsigned int)pow(10,p1);
						if(p2) 
							n2 = n2*(unsigned int)pow(10,p2);

                        if (ss.compare("ADD") == 0 )
                            res = n1+n2;
                        else if (ss.compare("MUL") == 0 )
                            res = n1*n2;
                        else if (ss.compare("DIV") == 0 )
                            res = n1/n2;
                        else
                            res = n1-n2;

                        thrust::device_ptr<int_type> p = thrust::device_malloc<int_type>(a->mRecCount);
                        thrust::sequence(p, p+(a->mRecCount),res,(int_type)0);

                        exe_type.push("VECTOR");
                        exe_vectors.push(thrust::raw_pointer_cast(p));
                    }
                    else if (s1.compare("FLOAT") == 0 && s2.compare("FLOAT") == 0) {
                        n1_f = exe_nums_f.top();
                        exe_nums_f.pop();
                        n2_f = exe_nums_f.top();
                        exe_nums_f.pop();

                        if (ss.compare("ADD") == 0 )
                            res_f = n1_f+n2_f;
                        else if (ss.compare("MUL") == 0 )
                            res_f = n1_f*n2_f;
                        else if (ss.compare("DIV") == 0 )
                            res_f = n1_f/n2_f;
                        else
                            res_f = n1_f-n2_f;

                        thrust::device_ptr<float_type> p = thrust::device_malloc<float_type>(a->mRecCount);
                        thrust::sequence(p, p+(a->mRecCount),res_f,(float_type)0);

                        exe_type.push("VECTOR F");
                        exe_vectors_f.push(thrust::raw_pointer_cast(p));

                    }

                    else if (s1.compare("NAME") == 0 && s2.compare("FLOAT") == 0) {
                        s1_val = exe_value.top();
                        exe_value.pop();
                        n1_f = exe_nums_f.top();
                        exe_nums_f.pop();

                        exe_type.push("VECTOR F");

                        if (a->type[s1_val] == 1) {
                            float_type* t = a->get_float_type_by_name(s1_val);
                            exe_vectors_f.push(a->op(t,n1_f,ss,1));
                        }
                        else {
                            int_type* t = a->get_int_by_name(s1_val);
                            exe_vectors_f.push(a->op(t,n1_f,ss,1));
                        };

                    }
                    else if (s1.compare("FLOAT") == 0 && s2.compare("NAME") == 0) {
                        n1_f = exe_nums_f.top();
                        exe_nums_f.pop();
                        s2_val = exe_value.top();
                        exe_value.pop();

                        exe_type.push("VECTOR F");

                        if (a->type[s2_val] == 1) {
                            float_type* t = a->get_float_type_by_name(s2_val);
                            exe_vectors_f.push(a->op(t,n1_f,ss,0));
                        }
                        else {
                            int_type* t = a->get_int_by_name(s2_val);
                            exe_vectors_f.push(a->op(t,n1_f,ss,0));
                        };
                    }
                    else if (s1.compare("NAME") == 0 && s2.compare("NUMBER") == 0) {

                        s1_val = exe_value.top();
                        exe_value.pop();
                        n1 = exe_nums.top();
                        exe_nums.pop();
						auto p1 = exe_precision.top();
						exe_precision.pop();
						auto p2 = a->decimal_zeroes[s1_val];					


                        if (a->type[s1_val] == 1) {
                            float_type* t = a->get_float_type_by_name(s1_val);
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(t,(float_type)n1,ss,1));
                        }
                        else {
                            int_type* t = a->get_int_by_name(s1_val);							
							auto pres = precision_func(p2, p1, ss);	
							exe_precision.push(pres);
                            exe_type.push("VECTOR");						
                            exe_vectors.push(a->op(t,n1,ss,1, p2, p1));
                        };
                    }
                    else if (s1.compare("NUMBER") == 0 && s2.compare("NAME") == 0) {
                        n1 = exe_nums.top();
                        exe_nums.pop();
                        s2_val = exe_value.top();
                        exe_value.pop();
						auto p1 = exe_precision.top();
						exe_precision.pop();
						auto p2 = a->decimal_zeroes[s2_val];					

                        if (a->type[s2_val] == 1) {
                            float_type* t = a->get_float_type_by_name(s2_val);
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(t,(float_type)n1,ss,0));
                        }
                        else {
                            int_type* t = a->get_int_by_name(s2_val);
							auto pres = precision_func(p2, p1, ss);	
							exe_precision.push(pres);
                            exe_type.push("VECTOR");
                            exe_vectors.push(a->op(t,n1,ss,0, p2, p1));
                        };
                    }
                    else if (s1.compare("NAME") == 0 && s2.compare("NAME") == 0) {
                        s1_val = exe_value.top();
                        exe_value.pop();
                        s2_val = exe_value.top();
                        exe_value.pop();
						

                        if (a->type[s1_val] == 0) {
                            int_type* t1 = a->get_int_by_name(s1_val);
                            if (a->type[s2_val] == 0) {
                                int_type* t = a->get_int_by_name(s2_val);
								auto p1 = a->decimal_zeroes[s1_val];					
								auto p2 = a->decimal_zeroes[s2_val];					
								auto pres = precision_func(p1, p2, ss);	
								exe_precision.push(pres);

                                exe_type.push("VECTOR");
                                exe_vectors.push(a->op(t,t1,ss,0,p2,p1));
                            }
                            else {
                                float_type* t = a->get_float_type_by_name(s2_val);
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t1,t,ss,0));
                            };
                        }
                        else {
                            float_type* t = a->get_float_type_by_name(s1_val);
                            if (a->type[s2_val] == 0) {
                                int_type* t1 = a->get_int_by_name(s2_val);
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t1,t,ss,0));
                            }
                            else {
                                float_type* t1 = a->get_float_type_by_name(s2_val);
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t1,t,ss,0));
                            };
                        }
                    }
                    else if ((s1.compare("VECTOR") == 0 || s1.compare("VECTOR F") == 0 ) && s2.compare("NAME") == 0) {

                        s2_val = exe_value.top();
                        exe_value.pop();

                        if (a->type[s2_val] == 0) {
                            int_type* t = a->get_int_by_name(s2_val);

                            if (s1.compare("VECTOR") == 0 ) {
                                int_type* s3 = exe_vectors.top();
                                exe_vectors.pop();
                                exe_type.push("VECTOR");
								auto p1 = exe_precision.top();
								exe_precision.pop();
								auto p2 = a->decimal_zeroes[s2_val];					
								auto pres = precision_func(p1, p2, ss);	
								exe_precision.push(pres);
                                exe_vectors.push(a->op(t,s3,ss,0,p2,p1));
								alloced_mem.push_back(s3);
                            }
                            else {
                                float_type* s3 = exe_vectors_f.top();
                                exe_vectors_f.pop();
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t,s3,ss,0));
								alloced_mem.push_back(s3);
                            }
                        }
                        else {
                            float_type* t = a->get_float_type_by_name(s2_val);
                            if (s1.compare("VECTOR") == 0 ) {
                                int_type* s3 = exe_vectors.top();
                                exe_vectors.pop();
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(s3,t, ss,0));
								alloced_mem.push_back(s3);
                            }
                            else {
                                float_type* s3 = exe_vectors_f.top();
                                exe_vectors_f.pop();
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t,s3,ss,0));
								alloced_mem.push_back(s3);
                            }
                        };
                    }
                    else if ((s2.compare("VECTOR") == 0 || s2.compare("VECTOR F") == 0 ) && s1.compare("NAME") == 0) {

                        s1_val = exe_value.top();
                        exe_value.pop();

                        if (a->type[s1_val] == 0) {
                            int_type* t = a->get_int_by_name(s1_val);

                            if (s2.compare("VECTOR") == 0 ) {
                                int_type* s3 = exe_vectors.top();
                                exe_vectors.pop();
                                exe_type.push("VECTOR");
								auto p1 = exe_precision.top();
								exe_precision.pop();
								auto p2 = a->decimal_zeroes[s1_val];					
								auto pres = precision_func(p1, p2, ss);	
								exe_precision.push(pres);
                                exe_vectors.push(a->op(t,s3,ss,1,p2,p1));
								alloced_mem.push_back(s3);
                            }
                            else {
                                float_type* s3 = exe_vectors_f.top();
                                exe_vectors_f.pop();
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t,s3,ss,1));
								alloced_mem.push_back(s3);
                            }
                        }
                        else {

                            float_type* t = a->get_float_type_by_name(s1_val);
                            if (s2.compare("VECTOR") == 0 ) {
                                int_type* s3 = exe_vectors.top();
                                exe_vectors.pop();
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(s3,t,ss,1));
								alloced_mem.push_back(s3);
                            }
                            else {
                                float_type* s3 = exe_vectors_f.top();
                                exe_vectors_f.pop();
                                exe_type.push("VECTOR F");
                                exe_vectors_f.push(a->op(t,s3,ss,1));
								alloced_mem.push_back(s3);
                            }
                        };
                    }
                    else if ((s1.compare("VECTOR") == 0 || s1.compare("VECTOR F") == 0)  && s2.compare("NUMBER") == 0) {
                        n1 = exe_nums.top();
                        exe_nums.pop();

                        if (s1.compare("VECTOR") == 0 ) {
                            int_type* s3 = exe_vectors.top();
                            exe_vectors.pop();
                            exe_type.push("VECTOR");
							auto p1 = exe_precision.top();
							exe_precision.pop();
							auto p2 = exe_precision.top();
							exe_precision.pop();							
							auto pres = precision_func(p1, p2, ss);	
							exe_precision.push(pres);
                            exe_vectors.push(a->op(s3,n1, ss,1, p1, p2));
                            //cudaFree(s3);
							alloced_mem.push_back(s3);
                        }
                        else {
                            float_type* s3 = exe_vectors_f.top();
                            exe_vectors_f.pop();
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(s3,(float_type)n1, ss,1));
							alloced_mem.push_back(s3);
                        }
                    }
                    else if (s1.compare("NUMBER") == 0 && (s2.compare("VECTOR") || s2.compare("VECTOR F") == 0)) {
                        n1 = exe_nums.top();
                        exe_nums.pop();

                        if (s2.compare("VECTOR") == 0 ) {
                            int_type* s3 = exe_vectors.top();
                            exe_vectors.pop();
                            exe_type.push("VECTOR");
							auto p1 = exe_precision.top();
							exe_precision.pop();
							auto p2 = exe_precision.top();
							exe_precision.pop();							
							auto pres = precision_func(p2, p1, ss);	
							exe_precision.push(pres);	
                            exe_vectors.push(a->op(s3,n1, ss,0, p2, p1));
							alloced_mem.push_back(s3);
                        }
                        else {
                            float_type* s3 = exe_vectors_f.top();
                            exe_vectors_f.pop();
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(s3,(float_type)n1, ss,0));
							alloced_mem.push_back(s3);
                        }
                    }

                    else if ((s1.compare("VECTOR") == 0 || s1.compare("VECTOR F") == 0)  && s2.compare("FLOAT") == 0) {

                        n1_f = exe_nums_f.top();
                        exe_nums_f.pop();

                        if (s1.compare("VECTOR") == 0 ) {
                            int_type* s3 = exe_vectors.top();
                            exe_vectors.pop();
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(s3,n1_f, ss,1));
							alloced_mem.push_back(s3);
                        }
                        else {
                            float_type* s3 = exe_vectors_f.top();
                            exe_vectors_f.pop();
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(s3,n1_f, ss,1));
							alloced_mem.push_back(s3);
                        }
                    }
                    else if (s1.compare("FLOAT") == 0 && (s2.compare("VECTOR") == 0 || s2.compare("VECTOR F") == 0)) {
                        n1_f = exe_nums_f.top();
                        exe_nums_f.pop();

                        if (s2.compare("VECTOR") == 0 ) {
                            int_type* s3 = exe_vectors.top();
                            exe_vectors.pop();
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(s3,n1_f, ss,0));
							alloced_mem.push_back(s3);
                        }
                        else {
                            float_type* s3 = exe_vectors_f.top();
                            exe_vectors_f.pop();
                            exe_type.push("VECTOR F");
                            exe_vectors_f.push(a->op(s3,n1_f, ss,0));
							alloced_mem.push_back(s3);
                        }
                    }

                    else if (s1.compare("VECTOR") == 0 && s2.compare("VECTOR") == 0) {
                        int_type* s3 = exe_vectors.top();
                        exe_vectors.pop();
                        int_type* s4 = exe_vectors.top();
                        exe_vectors.pop();
                        exe_type.push("VECTOR");
						auto p1 = exe_precision.top();
						exe_precision.pop();
						auto p2 = exe_precision.top();
						exe_precision.pop();
						auto pres = precision_func(p1, p2, ss);	
						exe_precision.push(pres);	
                        exe_vectors.push(a->op(s3, s4,ss,0,p1,p2));
						alloced_mem.push_back(s3);
						alloced_mem.push_back(s4);
                    }
                    else if(s1.compare("VECTOR") == 0 && s2.compare("VECTOR F") == 0) {
                        int_type* s3 = exe_vectors.top();
                        exe_vectors.pop();
                        float_type* s4 = exe_vectors_f.top();
                        exe_vectors_f.pop();
                        exe_type.push("VECTOR F");
                        exe_vectors_f.push(a->op(s3, s4,ss,1));
						alloced_mem.push_back(s3);
						alloced_mem.push_back(s4);
                    }
                    else if(s1.compare("VECTOR F") == 0 && s2.compare("VECTOR") == 0) {
                        int_type* s3 = exe_vectors.top();
                        exe_vectors.pop();
                        float_type* s4 = exe_vectors_f.top();
                        exe_vectors_f.pop();
                        exe_type.push("VECTOR F");
                        exe_vectors_f.push(a->op(s3, s4,ss,0));
						alloced_mem.push_back(s3);
						alloced_mem.push_back(s4);
                    }
                    else if(s1.compare("VECTOR F") == 0 && s2.compare("VECTOR F") == 0) {
                        float_type* s3 = exe_vectors_f.top();
                        exe_vectors_f.pop();
                        float_type* s4 = exe_vectors_f.top();
                        exe_vectors_f.pop();
                        exe_type.push("VECTOR F");
                        exe_vectors_f.push(a->op(s3, s4,ss,1));
						alloced_mem.push_back(s3);
						alloced_mem.push_back(s4);
                    }
                }
            }

        } //
        else {
            // here we need to save what is where
			
            col_val.push(op_value.front());
            op_value.pop();
            grp_type1.push(grp_type);

            if(!exe_nums.empty()) {  //number
                col_type.push(0);
                exe_nums1.push(exe_nums.top());
                exe_nums.pop();
				exe_precision1.push(exe_precision.top());				
				exe_precision.pop();
            };
            if(!exe_value.empty()) {  //field name
                col_type.push(1);
				exe_precision1.push(a->decimal_zeroes[exe_value.top()]);
                exe_value1.push(exe_value.top());
				exe_ts.push(ts);				
                exe_value.pop();												
            };
            if(!exe_vectors.empty()) {  //vector int
                exe_vectors1.push(exe_vectors.top());
                exe_vectors.pop();
                col_type.push(2);
				exe_precision1.push(exe_precision.top());
				exe_precision.pop();
            };
            if(!exe_vectors_f.empty()) {  //vector float
                exe_vectors1_d.push(exe_vectors_f.top());
                exe_vectors_f.pop();
                col_type.push(3);
            };

            colCount++;
        };
    };
	
		
    for(unsigned int j=0; j < colCount; j++) {	
	    if ((grp_type1.top()).compare("COUNT") == 0 )
            b->grp_type[col_val.top()] = 0;
        else if ((grp_type1.top()).compare("AVG") == 0 )
            b->grp_type[col_val.top()] = 1;
        else if ((grp_type1.top()).compare("SUM") == 0 )
            b->grp_type[col_val.top()] = 2;
        else if ((grp_type1.top()).compare("NULL") == 0 )
            b->grp_type[col_val.top()] = 3;
        else if ((grp_type1.top()).compare("MIN") == 0 )
            b->grp_type[col_val.top()] = 4;
        else if ((grp_type1.top()).compare("MAX") == 0 )
            b->grp_type[col_val.top()] = 5;
        else if ((grp_type1.top()).compare("COUNTD") == 0 ) {
            b->grp_type[col_val.top()] = 6;
        };
		

        if(col_type.top() == 0) {
            // create a vector
            if (a->grp_count) {
                thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                thrust::copy_if(thrust::make_constant_iterator((int)exe_nums1.top()), thrust::make_constant_iterator((int)exe_nums1.top()) + a->mRecCount, d_di, count_diff, thrust::identity<bool>());
                b->addDeviceColumn(thrust::raw_pointer_cast(count_diff) , col_val.top(), res_size);
                thrust::device_free(count_diff);
            }
            else {
				thrust::device_ptr<int_type> s = thrust::device_malloc<int_type>(a->mRecCount);
				thrust::sequence(s, s+(a->mRecCount), (int)exe_nums1.top(), 0);
				b->addDeviceColumn(thrust::raw_pointer_cast(s), col_val.top(), a->mRecCount);
			}	
            exe_nums1.pop();		
			b->decimal_zeroes[col_val.top()] = exe_precision1.top();
			exe_precision1.pop();		
			
        }
        else if(col_type.top() == 1) {
		
            if(a->type[exe_value1.top()] == 0 || a->type[exe_value1.top()] == 2) {
			
                //modify what we push there in case of a grouping
                if (a->grp_count) {
                    thrust::device_ptr<int_type> count_diff = thrust::device_malloc<int_type>(res_size);
                    if(!exe_ts.top()) {
						thrust::copy_if(a->d_columns_int[exe_value1.top()].begin(),a->d_columns_int[exe_value1.top()].begin() + a->mRecCount,
										d_di, count_diff, thrust::identity<bool>());
					}					
					else {				
						
						thrust::device_vector<unsigned int> dd_tmp(res_size);
						thrust::copy_if(rcol_matches.begin(), rcol_matches.end(), d_di, dd_tmp.begin(), thrust::identity<bool>());
						thrust::gather(dd_tmp.begin(), dd_tmp.end(), rcol_dev.begin(), count_diff);														
										
					};
                    b->addDeviceColumn(thrust::raw_pointer_cast(count_diff) ,  col_val.top(), res_size);
                    thrust::device_free(count_diff);
                }
                else
                    b->addDeviceColumn(thrust::raw_pointer_cast(a->d_columns_int[exe_value1.top()].data()) , col_val.top(), a->mRecCount);
					
				if(a->type[exe_value1.top()] == 0) {
					b->decimal_zeroes[col_val.top()] = exe_precision1.top();
					b->ts_cols[col_val.top()] = exe_ts.top();
				};
					
                if(a->type[exe_value1.top()] == 2 || (a->type[exe_value1.top()] == 0 && a->string_map.find(exe_value1.top()) != a->string_map.end())) {
                    b->string_map[col_val.top()] = a->string_map[exe_value1.top()];
                };
				exe_precision1.pop();		
				exe_ts.pop();					
            }
            else if(a->type[exe_value1.top()] == 1) {
                //modify what we push there in case of a grouping
                if (a->grp_count) {
                    thrust::device_ptr<float_type> count_diff = thrust::device_malloc<float_type>(res_size);
                    //thrust::device_ptr<bool> d_grp(a->grp);
                    thrust::copy_if(a->d_columns_float[exe_value1.top()].begin(), a->d_columns_float[exe_value1.top()].begin() + a->mRecCount,
                                    d_di, count_diff, thrust::identity<bool>());
                    b->addDeviceColumn(thrust::raw_pointer_cast(count_diff) , col_val.top(), res_size, a->decimal[exe_value1.top()]);
                    thrust::device_free(count_diff);
                }
                else {
                    b->addDeviceColumn(thrust::raw_pointer_cast(a->d_columns_float[exe_value1.top()].data()), col_val.top(), a->mRecCount, a->decimal[exe_value1.top()]);
				};	
            }
            exe_value1.pop();	
        }
        else if(col_type.top() == 2) {	    // int

            if (a->grp_count)
                b->addDeviceColumn(exe_vectors1.top() , col_val.top(), res_size);
            else {
                if(!one_line)
                    b->addDeviceColumn(exe_vectors1.top() , col_val.top(), a->mRecCount);
                else
                    b->addDeviceColumn(exe_vectors1.top() , col_val.top(), 1);
            };
            cudaFree(exe_vectors1.top());
            exe_vectors1.pop();
			b->decimal_zeroes[col_val.top()] = exe_precision1.top();
			exe_precision1.pop();		
			
        }
        else if(col_type.top() == 3) {        //float
		
            if (a->grp_count) {
                b->addDeviceColumn(exe_vectors1_d.top() , col_val.top(), res_size, 1);
            }
            else {
                if(!one_line) {
                    b->addDeviceColumn(exe_vectors1_d.top() , col_val.top(), a->mRecCount, 1);
                }
                else {
                    b->addDeviceColumn(exe_vectors1_d.top() , col_val.top(), 1, 1);
                };
            };
            cudaFree(exe_vectors1_d.top());
            exe_vectors1_d.pop();
        };
        col_type.pop();
        col_val.pop();
        grp_type1.pop();
    };


    if (!a->grp_count) {
        if(!one_line)
            b->mRecCount = a->mRecCount;
        else
            b->mRecCount = 1;
        one_liner = one_line;
    }
    else {
        b->mRecCount = res_size;
        one_liner = 0;
    };
}


